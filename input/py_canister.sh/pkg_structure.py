#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import copy
import pathlib
import platform
import re
import json
import getpass

class PkgStructure(object):
    """
    Infer the directory structure of the software package from script path.
    """
    NONDIR_KEYS = ['pkg_name', 'exec_user',  
                   'base_script', 'script_mnemonic', 'script_path', 'script_basename']
    BASE_KEYS   = NONDIR_KEYS + ['pkg_path', 'script_location', 'prefix']

    def __init__(self, script_path=None, env_input=None, prefix=None, pkg_name=None,
                 flg_realpath=False, remove_tail_digits=True, remove_head_dots=True,
                 mimic_home=True, unnecessary_exts=['.sh', '.py', '.tar.gz'], **args):
        self.pkg_info = {}
        if isinstance(env_input, PkgStructure):
            self.pkg_info.update(env_input.pkg_info)
        elif isinstance(env_input, dict):
            self.pkg_info.update(env_input)
        else:
            PkgStructure.set_info(data=self.pkg_info, script_path=script_path, prefix=prefix, pkg_name=pkg_name,
                                  flg_realpath=flg_realpath, remove_tail_digits=remove_tail_digits, mimic_home=mimic_home,
                                  remove_head_dots=remove_head_dots, unnecessary_exts=unnecessary_exts, **args)

    def is_keyword(self, query):
        return query in self.pkg_info.keys()

    def is_dir_keyword(self, query):
        return ( ( query in self.pkg_info.keys() )
                 and ( not query in PkgStructure.NONDIR_KEYS ) )

    def make_subdirs(self, key, permission=0o755, exist_ok=True, *args):
        _path=self.concat_path(key, *args)
        os.makedirs(_path, mode=permission, exist_ok=exist_ok)
        return _path

    def concat_path(self, key, *args,
                    make_parents=False, dir_permission=0o755, exist_ok=True,
                    touch=False, permission=0o644, return_pathobj=False):

        if ( key in PkgStructure.BASE_KEYS ) or ( self.pkg_info.get(key) is None):
            raise ValueError("Invalid key %s PkgStructure::concat_path() accepts valid variable name except for PkgStructure.BASE_KEYS : %s" 
                             % (str(key), str(PkgStructure.BASE_KEYS)))

        _path = os.path.join(self.pkg_info[key], *args)

        if make_parents:
            os.makedirs(os.path.dirname(_path), mode=dir_permission, exist_ok=exist_ok)

        if touch:
            pathlib.Path(_path).touch(mode=permission, exist_ok=exist_ok)

        return pathlib.Path(_path) if return_pathobj else _path

    @classmethod
    def guess_pkgtop(cls, script_path, flg_realpath=False):
        _loc, _bn = cls.ana_script_location(script_path=script_path, flg_realpath=flg_realpath)
        _locpath = pathlib.Path(_loc)
        if _locpath.parts[-2:]==('lib', 'python'):
            _top=_locpath.parents[1]
        elif _locpath.parts[-1:]==('bin',):
            _top=_locpath.parents[0]
        else:
            _top=_locpath
        return _top

    @classmethod
    def guess_pkgname(cls, script_path, script_top, remove_tail_digits=True, remove_head_dots=True,
                      unnecessary_exts=['.sh', '.py', '.tar.gz']):
        _top_abs=pathlib.Path(os.path.abspath(script_top))
        _pkg_name = script_top.name
        if _pkg_name in [ '.', '..', '', '/',
                          'usr', 'local', 'opt', 'tmp', 'var', 'etc',
                          'User' if platform.system() == "Darwin" else 'home', None]:
            _pkg_name = cls.strip_aux_modifier(pathlib.Path(script_path).stem,
                                               remove_tail_digits=remove_tail_digits,
                                               remove_head_dots=remove_head_dots,
                                               unnecessary_exts=unnecessary_exts)
        return _pkg_name

    @classmethod
    def guess_pkg_info(cls, script_path, flg_realpath=False, remove_tail_digits=True, remove_head_dots=True):
        _pkg_top  = cls.guess_pkgtop(script_path=script_path, flg_realpath=flg_realpath)
        _pkg_name = cls.guess_pkgname(script_path=script_path, script_top=_pkg_top,
                                      remove_tail_digits=remove_tail_digits, remove_head_dots=remove_head_dots)
        if isinstance(_pkg_name, str) and len(_pkg_name)<1:
            _pkg_name = None

        return (_pkg_name, _pkg_top)

    @classmethod
    def ana_script_location(cls, script_path, flg_realpath=False):
        _scr_path = os.path.normpath(os.path.realpath(script_path) if flg_realpath else script_path)
        _loc,_bn  = os.path.split(_scr_path)
        return (_loc, _bn)

    @classmethod
    def strip_aux_modifier(cls, filename, remove_tail_digits=True, remove_head_dots=True,
                           unnecessary_exts=['.sh', '.py', '.tar.gz']):
        stripped=filename
        for ext in unnecessary_exts:
            if filename.endswith(ext):
                _m = filename[:-len(ext)]
                if len(_m)>0:
                    stripped=_m
                    break

        if remove_head_dots and stripped.startswith('.'):
            _m = stripped.lstrip('.')
            if len(_m)>0:
                stripped=_m

        if remove_tail_digits:
            _m = stripped.rstrip('0123456789.-_')
            if len(_m)>0:
                stripped=_m
        return stripped

    @classmethod
    def guess_script_info(cls, script_path, flg_realpath=False, remove_tail_digits=True,
                          remove_head_dots=True, unnecessary_exts=['.sh', '.py', '.tar.gz']):
        _loc, _bn     = cls.ana_script_location(script_path=script_path, flg_realpath=flg_realpath)
        _scr_mnemonic = cls.strip_aux_modifier(_bn, remove_tail_digits=remove_tail_digits,
                                               remove_head_dots=remove_head_dots,
                                               unnecessary_exts=unnecessary_exts)
        return (_bn, _loc, _scr_mnemonic)



    @classmethod
    def set_info(cls, data={}, script_path=None, prefix=None, pkg_name=None,
                 flg_realpath=False, remove_tail_digits=True, mimic_home=True,
                 remove_head_dots=True, unnecessary_exts=['.sh', '.py', '.tar.gz'], **args):

        _scr_path= ( str(script_path) if ( script_path is not None ) else 
                     ( sys.argv[0] if os.path.exists(sys.argv[0]) else  __file__ ))
        
        data['base_script']   = _scr_path
        _bn, _loc, _scr_mnemonic = cls.guess_script_info(script_path,
                                                         flg_realpath=flg_realpath, remove_tail_digits=remove_tail_digits,
                                                         remove_head_dots=remove_head_dots, unnecessary_exts=unnecessary_exts)

        data['script_path']     = os.path.realpath(script_path) if flg_realpath else script_path
        data['script_mnemonic'] = _scr_mnemonic
        data['script_location'] = _loc
        data['script_basename'] = _bn

        _pkg_name, _pkg_top = cls.guess_pkg_info(_scr_path, flg_realpath=flg_realpath,
                                                 remove_tail_digits=remove_tail_digits, remove_head_dots=remove_head_dots)

        data['pkg_path'] = str(_pkg_top)
        data['prefix']   = prefix   if isinstance(prefix, str)   else str(_pkg_top)
        data['pkg_name'] = pkg_name if isinstance(pkg_name, str) else _pkg_name

        # 

        data['exec_user'] = getpass.getuser()

        # Variables :  GNU Coding Standards + FHS inspired
        data['exec_prefix']    = data['prefix']
        data['bindir']         = os.path.join(data['prefix'], 'bin')
        data['datarootdir']    = os.path.join(data['prefix'], 'share')
        data['datadir']        = data['datarootdir']
        data['sysconfdir']     = os.path.join(data['prefix'], 'etc')
        data['sharedstatedir'] = os.path.join(data['prefix'], 'com')
        data['localstatedir']  = os.path.join(data['prefix'], 'var')
        data['include']        = os.path.join(data['prefix'], 'include')
        data['libdir']         = os.path.join(data['prefix'], 'lib')
        data['srcdir']         = os.path.join(data['prefix'], 'src')
        data['infodir']        = os.path.join(data['datarootdir'], 'info')
        data['runstatedir']    = os.path.join(data['localstatedir'], 'run')
        data['localedir']      = os.path.join(data['datarootdir'], 'locale')
        data['lispdir']        = os.path.join(data['prefix'], 'emacs', 'lisp')
        #
        if len(data['pkg_name'])>0:
            data['docdir']         = os.path.join(data['prefix'], 'doc', data['pkg_name'])
        else:
            data['docdir']         = os.path.join(data['prefix'], 'doc')
        data['htmldir']        = data['docdir']
        data['dvidir']         = data['docdir']
        data['pdfdir']         = data['docdir']
        data['psdir']          = data['docdir']
        #
        data['mandir']         = os.path.join(data['datarootdir'], 'man')
        for _i in range(10):
            data["man%ddir" % (_i)] = os.path.join(data['mandir'], "man%d" % (_i))
        data["manndir"] = os.path.join(data['mandir'], "mann")
        #
        data['sbindir']        = os.path.join(data['prefix'], 'sbin')
        data['bootdir']        = os.path.join(data['prefix'], 'boot')
        data['devdir']         = os.path.join(data['prefix'], 'dev')
        data['mediadir']       = os.path.join(data['prefix'], 'media')
        data['mntdir']         = os.path.join(data['prefix'], 'mnt')
        data['optdir']         = os.path.join(data['prefix'], 'opt')
        data['tmpdir']         = os.path.join(data['prefix'], 'tmp')

        data['xmldir']         = os.path.join(data['sysconfdir'], 'xml')
        data['etcoptdir']      = os.path.join(data['sysconfdir'], 'opt')

        data['cachedir']       = os.path.join(data['localstatedir'], 'cache')
        data['statedatadir']   = os.path.join(data['localstatedir'], 'lib')
        data['lockdir']        = os.path.join(data['localstatedir'], 'lock')
        data['logdir']         = os.path.join(data['localstatedir'], 'log')
        data['spooldir']       = os.path.join(data['localstatedir'], 'spool')
        data['statetmpdir']    = os.path.join(data['localstatedir'], 'tmp')

        #
        if mimic_home:
            pathobj_home    = pathlib.Path.home()
            path_home_parts = pathobj_home.relative_to(pathobj_home.anchor).parts
            data['user_home'] = os.path.join(data['prefix'], *path_home_parts)
        else:
            data['user_home'] = pathlib.Path.home()
        data['home']    = data['user_home']
        data['homedir'] = os.path.dirname(data['user_home'])
        #
        _pkg_subdir_keys = ['datadir', 'sysconfdir', 'runstatedir', 'include', 'libdir', 'srcdir',
                            'tmpdir', 'xmldir', 'cachedir', 'statedatadir', 'lockdir', 'logdir', 'spooldir', 'statetmpdir']
        if len(data['pkg_name'])>0:
            for k in _pkg_subdir_keys:
                data['pkg_'+k] = os.path.join(data[k], data['pkg_name'])
        else:
            for k in _pkg_subdir_keys:
                data['pkg_'+k] = data[k]

        for k,val in args.items():
            data[k] = val

        return data

    @property
    def base_script(self):
        return data.get('base_script',    _scr_path)

    @property
    def script_path(self):
        return self.pkg_info['script_path']

    @property
    def script_mnemonic(self):
        return self.pkg_info['script_mnemonic']

    @property
    def script_location(self):
        return self.pkg_info['script_location']

    @property
    def script_basename(self):
        return self.pkg_info['script_basename']

    @property
    def pkg_path(self):
        return self.pkg_info['pkg_path']

    @property
    def prefix(self):
        return self.pkg_info['prefix']

    @property
    def pkg_name(self):
        return self.pkg_info['pkg_name']

    @property
    def exec_prefix(self):
        return self.pkg_info.get('exec_prefix', self.pkg_info['prefix'])

    @property
    def bindir(self):
        return self.pkg_info.get('bindir', os.path.join(self.pkg_info['prefix'], 'bin'))

    @property
    def datarootdir(self):
        return self.pkg_info.get('datarootdir', os.path.join(self.pkg_info['prefix'], 'share'))

    @property
    def datadir(self):
        return self.pkg_info.get('datadir', self.datarootdir)

    @property
    def sysconfdir(self):
        return self.pkg_info.get('sysconfdir', os.path.join(self.pkg_info['prefix'], 'etc'))

    @property
    def sharedstatedir(self):
        return self.pkg_info.get('sharedstatedir', os.path.join(self.pkg_info['prefix'], 'com'))

    @property
    def localstatedir(self):
        return self.pkg_info.get('localstatedir', os.path.join(self.pkg_info['prefix'], 'var'))

    @property
    def include(self):
        return self.pkg_info.get('include', os.path.join(self.pkg_info['prefix'], 'include'))

    @property
    def libdir(self):
        return self.pkg_info.get('libdir', os.path.join(self.pkg_info['prefix'], 'lib'))

    @property
    def srcdir(self):
        return self.pkg_info.get('srcdir', os.path.join(self.pkg_info['prefix'], 'src'))

    @property
    def infodir(self):
        return self.pkg_info.get('infodir', os.path.join(self.datarootdir, 'info'))

    @property
    def runstatedir(self):
        return self.pkg_info.get('runstatedir', os.path.join(self.localstatedir, 'run'))

    @property
    def localedir(self):
        return self.pkg_info.get('localedir', os.path.join(self.datarootdir, 'locale'))

    @property
    def lispdir(self):
        return self.pkg_info.get('lispdir', os.path.join(self.pkg_info['prefix'], 'emacs', 'lisp'))

    @property
    def docdir(self):
        return self.pkg_info.get('docdir',
                                 os.path.join(self.pkg_info['prefix'], 'doc', self.pkg_info['pkg_name'])
                                 if len(self.pkg_info['pkg_name'])>0 else
                                 os.path.join(self.pkg_info['prefix'], 'doc'))
    @property
    def htmldir(self):
        return self.pkg_info.get('htmldir', self.docdir)

    @property
    def dvidir(self):
        return self.pkg_info.get('dvidir', self.docdir)

    @property
    def pdfdir(self):
        return self.pkg_info.get('pdfdir', self.docdir)

    @property
    def psdir(self):
        return self.pkg_info.get('psdir', self.docdir)

    @property
    def mandir(self):
        return self.pkg_info.get('mandir', os.path.join(self.datarootdir, 'man'))

    @property
    def man1dir(self):
        return self.pkg_info.get('man1dir',  os.path.join(self.mandir, 'man1'))

    @property
    def man2dir(self):
        return self.pkg_info.get('man2dir',  os.path.join(self.mandir, 'man2'))

    @property
    def man3dir(self):
        return self.pkg_info.get('man3dir',  os.path.join(self.mandir, 'man3'))

    @property
    def man4dir(self):
        return self.pkg_info.get('man4dir',  os.path.join(self.mandir, 'man4'))

    @property
    def man5dir(self):
        return self.pkg_info.get('man5dir',  os.path.join(self.mandir, 'man5'))

    @property
    def man6dir(self):
        return self.pkg_info.get('man6dir',  os.path.join(self.mandir, 'man6'))

    @property
    def man7dir(self):
        return self.pkg_info.get('man7dir',  os.path.join(self.mandir, 'man7'))

    @property
    def man8dir(self):
        return self.pkg_info.get('man8dir',  os.path.join(self.mandir, 'man8'))

    @property
    def man9dir(self):
        return self.pkg_info.get('man9dir',  os.path.join(self.mandir, 'man9'))

    @property
    def manndir(self):
        return self.pkg_info.get('manndir',  os.path.join(self.mandir, 'mann'))

    @property
    def sbindir(self):
        return self.pkg_info.get('sbindir', os.path.join(self.prefix, 'sbin'))

    @property
    def bootdir(self):
        return self.pkg_info.get('bootdir', os.path.join(self.prefix, 'boot'))

    @property
    def devdir(self):
        return self.pkg_info.get('devdir', os.path.join(self.prefix, 'dev'))

    @property
    def homedir(self):
        return self.pkg_info.get('homedir', os.path.join(self.prefix, 'home'))

    @property
    def mediadir(self):
        return self.pkg_info.get('mediadir', os.path.join(self.prefix, 'media'))

    @property
    def mntdir(self):
        return self.pkg_info.get('mntdir', os.path.join(self.prefix, 'mnt'))

    @property
    def optdir(self):
        return self.pkg_info.get('optdir', os.path.join(self.prefix, 'opt'))

    @property
    def tmpdir(self):
        return self.pkg_info.get('tmpdir', os.path.join(self.prefix, 'tmp'))

    @property
    def xmldir(self):
        return self.pkg_info.get('xmldir', os.path.join(self.sysconfdir, 'xml'))

    @property
    def cachedir(self):
        return self.pkg_info.get('cachedir', os.path.join(self.localstatedir, 'cache'))

    @property
    def statedatadir(self):
        return self.pkg_info.get('statedatadir', os.path.join(self.localstatedir, 'lib'))

    @property
    def lockdir(self):
        return self.pkg_info.get('lockdir', os.path.join(self.localstatedir, 'lock'))

    @property
    def logdir(self):
        return self.pkg_info.get('logdir', os.path.join(self.localstatedir, 'log'))

    @property
    def spooldir(self):
        return self.pkg_info.get('spooldir', os.path.join(self.localstatedir, 'spool'))

    @property
    def statetmpdir(self):
        return self.pkg_info.get('statetmpdir', os.path.join(self.localstatedir, 'tmp'))

    @property
    def pkg_datadir(self):
        return self.pkg_info.get('pkg_datadir',
                                 os.path.join(self.datadir, self.pkg_info['pkg_name'])
                                 if len(self.pkg_info['pkg_name'])>0 else self.datadir)

    @property
    def pkg_sysconfdir(self):
        return self.pkg_info.get('pkg_sysconfdir',
                                 os.path.join(self.sysconfdir, self.pkg_info['pkg_name'])
                                 if len(self.pkg_info['pkg_name'])>0 else self.sysconfdir)

    @property
    def pkg_runstatedir(self):
        return self.pkg_info.get('pkg_runstatedir',
                                 os.path.join(self.runstatedir, self.pkg_info['pkg_name'])
                                 if len(self.pkg_info['pkg_name'])>0 else self.runstatedir)

    @property
    def pkg_include(self):
        return self.pkg_info.get('pkg_include',
                                 os.path.join(self.include, self.pkg_info['pkg_name'])
                                 if len(self.pkg_info['pkg_name'])>0 else self.include)

    @property
    def pkg_libdir(self):
        return self.pkg_info.get('pkg_libdir',
                                 os.path.join(self.libdir, self.pkg_info['pkg_name'])
                                 if len(self.pkg_info['pkg_name'])>0 else self.libdir)

    @property
    def pkg_srcdir(self):
        return self.pkg_info.get('pkg_srcdir',
                                 os.path.join(self.srcdir, self.pkg_info['pkg_name'])
                                 if len(self.pkg_info['pkg_name'])>0 else self.srcdir)
    @property
    def pkg_sbindir(self):
        return self.pkg_info.get('pkg_sbindir',
                                 os.path.join(self.sbindir,self.pkg_info['pkg_name'])
                                 if len(self.pkg_info['pkg_name'])>0 else self.sbindir)

    @property
    def pkg_tmpdir(self):
        return self.pkg_info.get('pkg_tmpdir',
                                 os.path.join(self.tmpdir,self.pkg_info['pkg_name'])
                                 if len(self.pkg_info['pkg_name'])>0 else self.tmpdir)

    @property
    def pkg_xmldir(self):
        return self.pkg_info.get('pkg_xmldir',
                                 os.path.join(self.xmldir,self.pkg_info['pkg_name'])
                                 if len(self.pkg_info['pkg_name'])>0 else self.xmldir)

    @property
    def pkg_cachedir(self):
        return self.pkg_info.get('pkg_cachedir',
                                 os.path.join(self.cachedir,self.pkg_info['pkg_name'])
                                 if len(self.pkg_info['pkg_name'])>0 else self.cachedir)

    @property
    def pkg_statedatadir(self):
        return self.pkg_info.get('pkg_statedatadir',
                                 os.path.join(self.statedatadir,self.pkg_info['pkg_name'])
                                 if len(self.pkg_info['pkg_name'])>0 else self.statedatadir)

    @property
    def pkg_lockdir(self):
        return self.pkg_info.get('pkg_lockdir',
                                 os.path.join(self.lockdir,self.pkg_info['pkg_name'])
                                 if len(self.pkg_info['pkg_name'])>0 else self.lockdir)

    @property
    def pkg_logdir(self):
        return self.pkg_info.get('pkg_logdir',
                                 os.path.join(self.logdir,self.pkg_info['pkg_name'])
                                 if len(self.pkg_info['pkg_name'])>0 else self.logdir)

    @property
    def pkg_spooldir(self):
        return self.pkg_info.get('pkg_spooldir',
                                 os.path.join(self.spooldir,self.pkg_info['pkg_name'])
                                 if len(self.pkg_info['pkg_name'])>0 else self.spooldir)

    @property
    def pkg_statetmpdir(self):
        return self.pkg_info.get('pkg_statetmpdir',
                                 os.path.join(self.statetmpdir,self.pkg_info['pkg_name'])
                                 if len(self.pkg_info['pkg_name'])>0 else self.statetmpdir)

    def __repr__(self):
        return json.dumps(self.pkg_info, ensure_ascii=False, indent=4, sort_keys=True)

    def __str__(self):
        return json.dumps(self.pkg_info, ensure_ascii=False, indent=4, sort_keys=True)

    def dump(self, relpath=True, with_seperator=True):
        base_info = ['pkg_name', 'pkg_path', '', 'base_script', '',
                     'script_mnemonic', 'script_path', 'script_location', 'script_basename', '', 'prefix', '', 'exec_user', '']
        tlmax = max([len(i) for i in base_info])
        seperator = '-'*70
        for k in base_info:
            if len(k)>0:
                print ( "%-*s %s" % (tlmax+4, "'"+k+"'"':', self.pkg_info[k]))
            elif with_seperator:
                print (seperator)

        # dlist1 = list(set(self.pkg_info.keys()) - set(base_info))
        dlist0 = [ k for k in self.pkg_info.keys() if not k in base_info ]
        dlist1 = [ k for k in dlist0 if not k.startswith('pkg_')]
        dlist2 = [ k for k in dlist0 if     k.startswith('pkg_')]
        tlmax = max([len(i) for i in dlist0])

        for k in dlist1+['']+dlist2+['']:
            if len(k)<1:
                if with_seperator:
                    print (seperator)
                continue
            if relpath:
                try:
                    _path = pathlib.Path(self.pkg_info[k]).relative_to(self.pkg_info['prefix'])
                    if len(str(_path))>0 and (not str(_path) == '.' ):
                        _path = os.path.join("'${prefix}'", _path)
                    else:
                        _path = "'${prefix}'"
                except ValueError:
                    _path = self.pkg_info[k]
            else:
                _path = self.pkg_info[k]
            print ( "%-*s %s" % (tlmax+4, "'"+k+"'"':', _path))

if __name__ == '__main__':
    import sys
    import argparse
    argpsr = argparse.ArgumentParser(description='Assigning the package directory structure/names',
                                     epilog='Directory structure/names are inspired by GNU Coding Standards and FHS')
    argpsr.add_argument('-H', '-C', '--class-help', action='store_true', help='show class help')
    argpsr.add_argument('-r', '--relative-path', action='store_true', help='show with relative path (default)')
    argpsr.add_argument('-a', '--absolute-path', action='store_true', help='show with absolute path')
    argpsr.add_argument('-S', '--without-separator', action='store_true', help='show without seperators')
    argpsr.add_argument('-s', '--with-separator',    action='store_true', help='show with seperators (default)')
    argpsr.add_argument('-j', '--json',              action='store_true', help='Show with JSON format')
    argpsr.add_argument('-N', '--non-mimic-home',    action='store_true', help='Not mimic home')

    argpsr.add_argument('filenames', nargs='*')
    args=argpsr.parse_args()
    if args.class_help:
        help(PkgStructure)
    else:
        for __f in args.filenames if len(args.filenames)>1 else sys.argv[:1]:
            __pkg_info=PkgStructure(script_path=__f, prefix=None, pkg_name=None,
                                    flg_realpath=False, remove_tail_digits=True,
                                    mimic_home=(not args.non_mimic_home),
                                    remove_head_dots=True, unnecessary_exts=['.sh', '.py', '.tar.gz'])
            if args.json:
                print(json.dumps(__pkg_info.pkg_info, ensure_ascii=False, indent=4, sort_keys=True))
            else:
                __pkg_info.dump(relpath=(not args.absolute_path), with_seperator=(not args.without_separator))


