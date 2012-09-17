# -*- coding: utf-8 -*-
#
# Copyright (c) 2011 Pawel Szostek (pawel.szostek@cern.ch)
#
#    This source code is free software; you can redistribute it
#    and/or modify it in source code form under the terms of the GNU
#    General Public License as published by the Free Software
#    Foundation; either version 2 of the License, or (at your option)
#    any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
#

import msg as p


class IDependable:
    def __init__(self):
        self.dep_index = 0;
        self._dep_fixed = False;
        self.__dep_provides = [];
        self.__dep_requires = [];
        self.__dep_depends_on = [];
        pass

    #use proxy template here
    def get_dep_provides(self):
        if self._dep_fixed == False:
            self.__create_deps()
        self._dep_fixed = True
        return self.__dep_provides

    def set_dep_provides(self, what):
        self.__dep_provides = what
    dep_provides = property(get_dep_provides, set_dep_provides)

    def get_dep_requires(self):
        if self._dep_fixed == False:
            self.__create_deps()
        self._dep_fixed = True
        return self.__dep_requires

    def set_dep_requires(self, what):
        self.__dep_requires = what
    dep_requires = property(get_dep_requires, set_dep_requires)

    def get_dep_depends_on(self):
        return self.__dep_depends_on

    def set_dep_depends_on(self, what):
        self.__dep_depends_on = what
    dep_depends_on = property(get_dep_depends_on, set_dep_depends_on)

    def __create_deps(self):
        """Used solely for polymorphism"""

class DependencySolver:
    def __init__(self):
        self.entities = {};

    def __lookup_post_provider(self, files, start_index, file):
        requires = file.dep_requires
        while True:
            start_index = start_index + 1
            try:
                if type(files[start_index]) == type(file):
                    f = files[start_index]
                else:
                    continue
            except IndexError:
                break

            if requires:
                for req in requires:
                    if req in f.dep_provides: 
                        return start_index
        return None

    def __find_provider_vhdl_file(self, files, req):
        for f in files:
            if req in f.dep_provides:
                return f

        return None

    def __find_provider_verilog_file(self, req, v_file):
        from srcfile import SourceFileFactory
        import os
        vf_dirname = v_file.dirname
        sff = SourceFileFactory()

        h_file = os.path.join(vf_dirname, req)
        if os.path.exists(h_file) and not os.path.isdir(h_file):
            return sff.new(h_file)

        inc_dirs = self.__parse_vlog_opt(v_file.vlog_opt)

        for dir in inc_dirs:
            dir = os.path.join(vf_dirname, dir)
            if not os.path.exists(dir) or not os.path.isdir(dir):
                p.warning("Include path "+dir+" doesn't exist")
                continue
            h_file = os.path.join(dir, req)
            if os.path.exists(h_file) and not os.path.isdir(h_file):
                return sff.new(h_file)
        return None

    def __parse_vlog_opt(self, vlog_opt):
        import re
        ret = []
        inc_pat = re.compile(".*?\+incdir\+([^ ]+)")
        while True:
            m = re.match(inc_pat, vlog_opt)
            if m:
                ret.append(m.group(1))
                vlog_opt = vlog_opt[m.end():]
            else:
                break
        return ret

    def solve(self, fileset):
        n_iter = 0
        max_iter = 100
        import copy

        fset = fileset.filter(IDependable);

        f_nondep = []

        done = False
        while not done and (n_iter < max_iter):
            n_iter = n_iter+1
            done = True
            for f in fset:
                if not f._dep_fixed:
                    idx = fset.index(f)
                    k = self.__lookup_post_provider(files=fset, start_index=idx, file=f);

                    if k:
                        done = False
                        #swap
                        fset[idx], fset[k] = fset[k], fset[idx]

        if(n_iter == max_iter):
            p.error("Maximum number of iterations reached when trying to solve the dependencies."+
            "Perhaps a cyclic inter-dependency problem.");
            return None

        for f in fset:
            if f._dep_fixed:
                f_nondep.append(copy.copy(f))
                del f

        f_nondep.sort(key=lambda f: f.dep_index)

        from srcfile import VHDLFile, VerilogFile
        for f in [file for file in fset if isinstance(file, VHDLFile)]:
            p.vprint(f.path)
            if f.dep_requires:
                for req in f.dep_requires:
                    pf = self.__find_provider_vhdl_file([file for file in fset if isinstance(file, VHDLFile)], req)
                    if not pf:
                        p.error("Missing dependency in file "+str(f)+": " + req[0]+'.'+req[1])
                    else:
                        p.vprint("--> " + pf.path);
                        if pf.path != f.path:
                            f.dep_depends_on.append(pf)
            #get rid of duplicates by making a set from the list and vice versa
            f.dep_depends_on = list(set(f.dep_depends_on))

        import srcfile as sf

        for f in [file for file in fset if isinstance(file, VerilogFile)]:
            p.vprint(f.path)
            if f.dep_requires:
                for req in f.dep_requires:
                    pf = self.__find_provider_verilog_file(req, f)
                    if not pf:
                        p.warning("Cannot find include for file "+str(f)+": "+req)
                    else:
                        p.vprint("--> " + pf.path)
                        f.dep_depends_on.append(pf)
            #get rid of duplicates by making a set from the list and vice versa
            f.dep_depends_on = list(set(f.dep_depends_on))

        newobj = sf.SourceFileSet();
        newobj.add(f_nondep);
        for f in fset:
            try:
                if not f._dep_fixed:
                    newobj.add(f)
            except:
                newobj.add(f)

        for k in newobj:
            p.vprint(str(k.dep_index) + " " + k.path + str(k._dep_fixed))
        return newobj
