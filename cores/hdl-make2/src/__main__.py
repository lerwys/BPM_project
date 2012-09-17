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


import os
from connection import Connection
import global_mod
import msg as p
import optparse
from module import Module
from fetch import ModulePool

def main():
    parser = optparse.OptionParser()

    parser.add_option("--manifest-help", action="store_true",
    dest="manifest_help", help="print manifest file variables description")

    parser.add_option("--make-sim", dest="make_sim", action="store_true",
    default=None, help="generate a simulation Makefile")

    parser.add_option("--make-fetch", dest="make_fetch", action="store_true",
    default=None, help="generate a makefile for modules' fetching")

    parser.add_option("--make-ise", dest="make_ise", action="store_true",
    default=None, help="generate a makefile for local ISE synthesis")

    parser.add_option("--make-remote", dest="make_remote", action="store_true",
    default=None, help="generate a makefile for remote synthesis")

    parser.add_option("-f", "--fetch", action="store_true", dest="fetch",
    default=None, help="fetch and/or update remote modules listed in Manifet")

    parser.add_option("--clean", action="store_true", dest="clean",
    default=None, help="remove all modules fetched for this one")

    parser.add_option("--list", action="store_true", dest="list",
    default=None, help="List all modules together with their files")
    
    parser.add_option("--list-files", action="store_true", dest="list_files",
    default=None, help="List all files in a from of a space-separated string")

    parser.add_option("--ise-proj", action="store_true", dest="ise_proj",
    default=None, help="create/update an ise project including list of project"
        "files")

    parser.add_option("-l", "--synthesize-locally", dest="local",
    default=None, action="store_true", help="perform a local synthesis")

    parser.add_option("-r", "--synthesize-remotelly", dest="remote",
    default=None, action="store_true", help="perform a remote synthesis")

    parser.add_option("--synth-server", dest="synth_server",
    default=None, help="use given SERVER for remote synthesis",
        metavar="SERVER")

    parser.add_option("--synth-user", dest="synth_user",
    default=None, help="use given USER for remote synthesis", metavar="USER")

    parser.add_option("--force-ise", dest="force_ise",
    default=None, type=float, help="Force given ISE version to be used in"
        " synthesis,use 0 for current version", metavar="ISE")

    parser.add_option("--py", dest="arbitrary_code",
    default="", help="add arbitrary code to all manifests' evaluation")

    parser.add_option("-v", "--verbose", dest="verbose", action="store_true",
    default="false", help="verbose mode")

    (options, _) = parser.parse_args()
    global_mod.options = options

    if options.manifest_help == True:
        from helper_classes import ManifestParser
        ManifestParser().help()
        quit()

    p.vprint("LoadTopManifest")
    pool = ModulePool()
    top_module = Module(parent=None, url=os.getcwd(), source="local",
        fetchto=".", pool=pool)
    pool.set_top_module(top_module)

    if top_module.manifest == None:
        p.echo("No manifest found. At least an empty one is needed")
        quit()
    global_mod.top_module = top_module
    global_mod.top_module.parse_manifest()

    global_mod.global_target = global_mod.top_module.target

    ssh = Connection(ssh_user=options.synth_user,
        ssh_server=options.synth_server)

    from hdlmake_kernel import HdlmakeKernel
    kernel = HdlmakeKernel(modules_pool=pool, connection=ssh, options=options)

    options_kernel_mapping = {
        "fetch" : "fetch",
        "make_sim" : "generate_modelsim_makefile",
        "ise_proj" : "generate_ise_project",
        "local" : "run_local_synthesis",
        "remote": "run_remote_synthesis",
        "make_fetch": "generate_fetch_makefile",
        "make_ise" : "generate_ise_makefile",
        "make_remote" : "generate_remote_synthesis_makefile",
        "list" : "list_modules",
        "clean" : "clean_modules"
    }
    sth_chosen = False
    for option, function in options_kernel_mapping.items():
        try:
            is_set = getattr(options, option)
            if is_set:
                sth_chosen = True
                getattr(kernel, function)()
        except Exception, unknown_error :
            print unknown_error

    if not sth_chosen:
        kernel.run()

if __name__ == "__main__":
    main()
