#!/usr/bin/python
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


import xml.dom.minidom as xml
import msg as p
import global_mod

xmlimpl = xml.getDOMImplementation()

ISE_STANDARD_LIBS = ['ieee','ieee_proposed','iSE','simprims','std',
'synopsys','unimacro','unisims','XilinxCoreLib']
QUARTUS_STANDARD_LIBS = ['altera', 'altera_mf', 'lpm', 'ieee', 'std']
MODELSIM_STANDARD_LIBS = ['ieee', 'std']

class ISEProjectProperty:
        def __init__(self,  name, value, is_default = False):
                self.name = name
                self.value = value
                self.is_default = is_default

        def emit_xml(self, doc):
                prop = doc.createElement("property")
                prop.setAttribute("xil_pn:name", self.name)
                prop.setAttribute("xil_pn:value", self.value)
                if self.is_default:
                        prop.setAttribute("xil_pn:valueState", "default")
                else:
                        prop.setAttribute("xil_pn:valueState", "non-default")

                return prop


class ISEProject:
        class FakeFile(list):
            def __init__(self):
                import  re
                self.append("")
                self.__blank = re.compile("^[ \t\n]+$")

            def write(self, what):
                import  re
                if what == "":
                    return
                elif re.match(self.__blank, what):
                    if self[len(self)-1] != "":
                        self.append("")
                    else:
                        pass
                elif what[len(what)-1] == "\n":
                    self[len(self)-1] += what[:len(what)-1]
                    self.append("")
                else:
                    self[len(self)-1] += what

        def __init__(self, ise, top_mod = None):
                self.props = []
                self.files = []
                self.libs = []
                self.xml_doc = None
                self.xml_files = []
                self.xml_props = []
                self.xml_libs = []
                self.xml_ise = None
                self.top_mod = top_mod
                self.ise = ise

        def add_files(self, files):
                self.files.extend(files);

        def __add_lib(self, lib):
            if lib not in self.libs:
                self.libs.append(lib)

        def add_libs(self, libs):
                for l in libs:
                    self.__add_lib(l)
                self.libs.remove('work')

        def add_property(self, prop):
                self.props.append(prop)

        def add_initial_properties(self, syn_device, syn_grade, syn_package, syn_top):
            family_names = {
              "XC6S" : "Spartan6",
              "XC3S" : "Spartan3",
              "XC6V" : "Virtex6",
              "XC5V" : "Virtex5",
              "XC4V" : "Virtex4" }
							
            self.add_property(ISEProjectProperty("Device", syn_device))
            self.add_property(ISEProjectProperty("Device Family", family_names[syn_device[0:4].upper()]))
            self.add_property(ISEProjectProperty("Speed Grade", syn_grade))
            self.add_property(ISEProjectProperty("Package", syn_package))
            self.add_property(ISEProjectProperty("Enable Multi-Threading", "2"))
            self.add_property(ISEProjectProperty("Enable Multi-Threading par", "4"))
            self.add_property(ISEProjectProperty("Implementation Top", "Architecture|"+syn_top))
            self.add_property(ISEProjectProperty("Manual Implementation Compile Order", "true"))
            self.add_property(ISEProjectProperty("Auto Implementation Top", "false"))
            self.add_property(ISEProjectProperty("Implementation Top Instance Path", "/"+syn_top))

        def __parse_props(self):
                for xmlp in self.xml_project.getElementsByTagName("properties")[0].getElementsByTagName("property"):
                        prop = ISEProjectProperty(
                                xmlp.getAttribute("xil_pn:name"),
                                xmlp.getAttribute("xil_pn:value"),
                                xmlp.getAttribute("xil_pn:valueState") == "default"
                                )

                        self.props.append(prop)
                self.xml_props = self.__purge_dom_node(name="properties", where=self.xml_doc.documentElement)

        def __parse_libs(self):
                for l in self.xml_project.getElementsByTagName("libraries")[0].getElementsByTagName("library"):
                        self.__add_lib(l.getAttribute("xil_pn:name"))
                self.xml_libs = self.__purge_dom_node(name="libraries", where=self.xml_doc.documentElement)

        def load_xml(self, filename):
                f = open(filename)
                self.xml_doc = xml.parse(f)
                self.xml_project =  self.xml_doc.getElementsByTagName("project")[0];
                import sys
                try:
                    self.__parse_props()
                except xml.parsers.expat.ExpatError:
                    p.rawprint("Error while parsing existng file's properties:")
                    p.rawprint(str(sys.exc_info()))
                    quit()

                try:
                    self.__parse_libs()
                except xml.parsers.expat.ExpatError:
                    p.rawprint("Error while parsing existng file's libraries:")
                    p.rawprint(str(sys.exc_info()))
                    quit()
                    
                where = self.xml_doc.documentElement
                self.xml_files = self.__purge_dom_node(name="files", where=where)
                self.xml_bindings = self.__purge_dom_node(name="bindings", where=where)
                try:
                    node = where.getElementsByTagName("version")[0]
                    self.ise = float(node.getAttribute("xil_pn:ise_version"))
                    where.removeChild(node)
                except:
                    pass
                f.close()

        def __purge_dom_node(self, name, where):
                try:
                    node = where.getElementsByTagName(name)[0]
                    where.removeChild(node)
                except:
                    pass
                new = self.xml_doc.createElement(name)
                where.appendChild(new)
                return new

        def __output_files(self, node):
            import os
            from srcfile import UCFFile, VHDLFile, VerilogFile, CDCFile, NGCFile

            for f in self.files:
                p.vprint("Writing .xise file for version " + str(self.ise))
                fp = self.xml_doc.createElement("file")
                fp.setAttribute("xil_pn:name", os.path.relpath(f.path))
                if isinstance(f, VHDLFile):
                        fp.setAttribute("xil_pn:type", "FILE_VHDL")
                elif isinstance(f, VerilogFile):
                        fp.setAttribute("xil_pn:type", "FILE_VERILOG")
                elif isinstance(f, UCFFile):
                        fp.setAttribute("xil_pn:type", "FILE_UCF")
                elif isinstance(f, CDCFile):
                        fp.setAttribute("xil_pn:type", "FILE_CDC")
                elif isinstance(f, NGCFile):
                        fp.setAttribute("xil_pn:type", "FILE_NGC")
                else:
                    continue

                assoc = self.xml_doc.createElement("association");
                assoc.setAttribute("xil_pn:name", "Implementation");
                assoc.setAttribute("xil_pn:seqID", str(self.files.index(f)+1));

                try:
                    if(f.library != "work"):
                        lib = self.xml_doc.createElement("library");
                        lib.setAttribute("xil_pn:name", f.library);
                        fp.appendChild(lib)
                except:
                    pass

                fp.appendChild(assoc)
                node.appendChild(fp);

        def __output_bindings(self, node):
            from srcfile import CDCFile
            for b in [f for f in self.files if isinstance(f, CDCFile)]:
                bp = self.xml_doc.createElement("binding")
                bp.setAttribute("xil_pn:location", self.top_mod.syn_top)
                bp.setAttribute("xil_pn:name",b.rel_path())
                node.appendChild(bp)

        def __output_props(self, node):
                for p in self.props:
                        node.appendChild(p.emit_xml(self.xml_doc))

        def __output_libs(self, node):
                for l in self.libs:
                        ll =  self.xml_doc.createElement("library")
                        ll.setAttribute("xil_pn:name", l);
                        node.appendChild(ll);

        def __output_ise(self, node):
            i = self.xml_doc.createElement("version")
            i.setAttribute("xil_pn:ise_version", str(self.ise))
            i.setAttribute("xil_pn:schema_version", "2")
            node.appendChild(i)

        def emit_xml(self, filename = None):
                if not self.xml_doc:
                        self.create_empty_project()
                else:
                        self.__output_ise(self.xml_doc.documentElement)
                self.__output_bindings(self.xml_bindings)
                self.__output_files(self.xml_files)
                self.__output_props(self.xml_props)
                self.__output_libs(self.xml_libs)
                f = open(filename, "w")
                fake = self.FakeFile()
                self.xml_doc.writexml(fake, newl = "\n", addindent="\t")
                f.write('\n'.join(fake))
                f.close()

        def create_empty_project(self):
                self.xml_doc = xmlimpl.createDocument("http://www.xilinx.com/XMLSchema", "project", None)
                top_element = self.xml_doc.documentElement
                top_element.setAttribute("xmlns", "http://www.xilinx.com/XMLSchema")
                top_element.setAttribute("xmlns:xil_pn", "http://www.xilinx.com/XMLSchema")

                header = self.xml_doc.createElement("header")
                header.appendChild(self.xml_doc.createTextNode(""))

                amf = self.xml_doc.createElement("autoManagedFiles")
                amf.appendChild(self.xml_doc.createTextNode(""))

                self.xml_props = self.xml_doc.createElement("properties")
                self.xml_files = self.xml_doc.createElement("files")
                self.xml_libs = self.xml_doc.createElement("libraries")
                self.xml_bindings = self.xml_doc.createElement("bindings")

                version = self.xml_doc.createElement("version")
                version.setAttribute("xil_pn:ise_version", self.ise);
                version.setAttribute("xil_pn:schema_version", "2");

                top_element.appendChild(header)
                top_element.appendChild(amf)
                top_element.appendChild(self.xml_props)
                top_element.appendChild(self.xml_libs)
                top_element.appendChild(self.xml_files)
                top_element.appendChild(self.xml_bindings)
                top_element.appendChild(version)


class ModelsiminiReader(object):
    def __init__(self, path = None):
        if path == None:
            path = self.modelsim_ini_dir() + "/modelsim.ini"
        self.path = path

    def get_libraries(self):
        import re
        new_section = "\[[^\[\]]+\]"
        libs = []

        try:
            ini = open(self.path, "r")
        except Exception:
            raise RuntimeError("Can't open existing Modelsim installation")

        reading_libraries = False
        for line in ini:
            line = line.split(";")[0]
            line = line.strip()
            if line == "": continue
            if line.lower() == "[library]":
                reading_libraries = True
                continue
            if re.search(new_section, line):
                if reading_libraries == True:
                    #reading_libraries = False
                    break
                else:
                    continue
            if reading_libraries:
                line = line.split('=')
                lib = line[0].strip()
                libs.append(lib.lower())
        return libs

    @staticmethod
    def modelsim_ini_dir():
        import os
        vsim_path = os.popen("which vsim").read().strip()
        bin_path = os.path.dirname(vsim_path)
        return os.path.abspath(bin_path+"/../")
