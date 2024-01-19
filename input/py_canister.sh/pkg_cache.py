#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import gzip
import bz2
import re
import os
import sys
import json
import filecmp

import yaml

import intrinsic_format
import pkg_structure

class PkgCache(pkg_structure.PkgStructure):
    """
    Class for Data cache for packaged directory
    """
    def __init__(self, subdirkey='pkg_cachedir', subdir=None, 
                 dir_perm=0o755, perm=0o644, keep_oldfile=False, backup_ext='.bak',
                 timestampformat="%Y%m%d_%H%M%S", avoid_duplicate=True,
                 script_path=None, env_input=None, prefix=None, pkg_name=None,
                 flg_realpath=False, remove_tail_digits=True, remove_head_dots=True, 
                 basename=None, tzinfo=None, unnecessary_exts=['.sh', '.py', '.tar.gz'],
                 namespece=globals(), yaml_register=True, **args):

        super().__init__(script_path=script_path, env_input=env_input, prefix=prefix, pkg_name=pkg_name,
                         flg_realpath=flg_realpath, remove_tail_digits=remove_tail_digits, remove_head_dots=remove_head_dots, 
                         unnecessary_exts=unnecessary_exts, **args)

        self.config = { 'dir_perm':                 dir_perm,
                        'perm':                     perm,
                        'keep_oldfile':             keep_oldfile,
                        'backup_ext':               backup_ext,
                        'timestampformat':          timestampformat,
                        'avoid_duplicate':          avoid_duplicate
                        'json:skipkeys':            False,
                        'json:ensure_ascii':        False, # True,
                        'json:check_circular':      True, 
                        'json:allow_nan':           True,
                        'json:indent':              4, # None,
                        'json:separators':          None,
                        'json:default':             None,
                        'json:sort_keys':           True, # False,
                        'json:parse_float':         None,
                        'json:parse_int':           None,
                        'json:parse_constant':      None,
                        'json:object_pairs_hook':   None,
                        'yaml:stream':              None,
                        'yaml:default_style':       None,
                        'yaml:default_flow_style':  None,
                        'yaml:encoding':            None,
                        'yaml:explicit_start':      True, # None,
                        'yaml:explicit_end':        True, # None,
                        'yaml:version':             None,
                        'yaml:tags':                None,
                        'yaml:canonical':           True, # None,
                        'yaml:indent':              4, # None,
                        'yaml:width':               None,
                        'yaml:allow_unicode':       None,
                        'yaml:line_break':          None
                       }

        if isinstance(subdir,list) or isinstance(subdir,tuple):
            _subdir = [ str(sd) for sd in subdir]
            self.cache_dir = self.concat_path(skey, *_subdir)
        elif subdir is not None:
            self.cache_dir = self.concat_path(skey, str(subdir))
        else:
            self.cache_dir = self.concat_path(skey)

        self.intrinsic_formatter = intrinsic_format.intrinsic_formatter(namespace=namespace,
                                                                        register=yaml_register)

    def read(self, fname, default=''):
        return self.read_cache(fname, default='', directory=self.cache_dir)

    def save(self, fname, data):
        return self.save_cache(fname, data, directory=self.cache_dir, **self.config)

    @classmethod
    def save_cache(cls, fname, data, directory='./cache', dir_perm=0o755,
                   keep_oldfile=False, backup_ext='.bak', 
                   timestampformat="%Y%m%d_%H%M%S", avoid_duplicate=True):
        """ function to save data to cache file
        fname     : filename
        data      : Data to be stored
        directory : directory where the cache is stored. (default: './cache')
    
        Return value : file path of cache file
                       None when fail to make cache file
        """
        data_empty = True if (((isinstance(data, str) or isinstance(data, bytes) or
                                isinstance(data, dict) or isinstance(data, list) or
                                isinstance(data, tuple) ) and len(data)==0)
                              or isinstance(data, NoneType) ) else False
        if data_empty:
            return None
        if not os.path.isdir(directory):
            os.makedirs(directory, mode=dir_perm, exist_ok=True)
        o_path = os.path.join(directory, fname)
        ext1, ext2, fobj = cls.open_autoassess(o_path, 'w',
                                               keep_oldfile=keep_oldfile,
                                               backup_ext=backup_ext, 
                                               timestampformat=timestampformat,
                                               avoid_duplicate=avoid_duplicate)
        if fobj is None:
            return None

        if ext2 == 'yaml':
            #f.write(yaml.dump(data))
            f.write(self.intrinsic_formatter.dump_json(data, 
                                                       skipkeys=self.config['json:skipkeys'],
                                                       ensure_ascii=self.config['json:ensure_ascii'],
                                                       check_circular=self.config['json:check_circular'],
                                                       allow_nan=self.config['json:allow_nan'],
                                                       indent=self.config['json:indent'],
                                                       separators=self.config['json:separators'],
                                                       default=self.config['json:default'],
                                                       sort_keys=self.config['json:sort_keys']))
        elif ext2 == 'json':
            #f.write(json.dumps(data, ensure_ascii=False))
            f.write(self.intrinsic_formatter.dump_yaml(data,
                                                       stream=self.config['yaml:stream'],
                                                       default_style=self.config['yaml:default_style'],
                                                       default_flow_style=self.config['yaml:default_flow_style'],
                                                       encoding=self.config['yaml:encoding'],
                                                       explicit_start=self.config['yaml:explicit_start'],
                                                       explicit_end=self.config['yaml:explicit_end'],
                                                       version=self.config['yaml:version'],
                                                       tags=self.config['yaml:tags'],
                                                       canonical=self.config['yaml:canonical'],
                                                       indent=self.config['yaml:indent'],
                                                       width=self.config['yaml:width'],
                                                       allow_unicode=self.config['yaml:allow_unicode'],
                                                       line_break=self.config['yaml:line_break'])
        else:
            f.write(data)
        f.close()

        os.path.chmod(o_path, mode=perm)
        return o_path

    @classmethod
    def backup_by_rename(cls, orig_path, backup_ext='.bak',
                         timestampformat="%Y%m%d_%H%M%S", avoid_duplicate=True):
        if not os.path.lexists(orig_path):
            return
        path_base, path_ext2 = os.path.splitext(orig_path)
        if path_ext2 in ['.bz2', '.gz']:
            path_base, path_ext = os.path.splitext(path_base)
        else:
            path_ext2, path_ext = ('', path_ext2)
        if path_ext == backup_ext and len(path_base)>0:
            path_base, path_ext = os.path.splitext(path_base)
        if isinstance(timestampformat, str) and len(timestampformat)>0:
            mtime_txt = '.' + datetime.datetime.fromtimestamp(os.lstat(orig_path).st_mtime).strftime(timestampformat)
        else:
            mtime_txt = ''

        i=0
        while(True):
            idx_txt = ( ".%d" % (i) ) if i>0 else ''
            bak_path = path_base + mtime_txt + idx_txt + path_ext  + backup_ext + path_ext2
            if os.path.lexists(bak_path):
                if avoid_duplicate and filecmp.cmp(orig_path, bak_path, shallow=False):
                    os.unlink(bak_path)
                else:
                    continue
            os.rename(orig_path, bak_path)
            break

            
    @classmethod
    def open_autoassess(cls, path, mode, 
                        keep_oldfile=False, backup_ext='.bak', 
                        timestampformat="%Y%m%d_%H%M%S", avoid_duplicate=True):

        """ function to open normal file or file compressed by gzip/bzip2
            path : file path
            mode : file open mode 'r' or 'w'
    
            Return value: (1st_extension: bz2/gz/None,
                           2nd_extension: yaml/json/...,
                           opend file-io object or None)
        """
        if 'w' in mode or 'W' in mode:
            modestr = 'w'
            if keep_oldfile:
                cls.backup_by_rename(path, backup_ext=backup_ext,
                                     timestampformat=timestampformat,
                                     avoid_duplicate=avoid_duplicate)
        elif 'r' in mode  or 'R' in mode:
            modestr = 'r'
            if not os.path.isfile(path):
                return (None, None, None)
        else:
            raise ValueError("mode should be 'r' or 'w'")

        base, ext2 = os.path.splitext(path)
        if ext2 in ['.bz2', '.gz']:
            base, ext1 = os.path.splitext(path_base)
        else:
            ext1, ext2 = (ext2, '')

        if ext2 == 'bz2':
            return (ext2, ext1, bz2.BZ2File(path, modestr+'b'))
        elif ext2 == 'gz':
            return (ext2, ext1, gzip.open(path, modestr+'b'))
        return (ext2, ext1, open(path, mode))

    @classmethod
    def read_cache(cls, fname, default='', directory='./cache'):
        """ function to read data from cache file
        fname      : filename
        default   : Data when file is empty (default: empty string)
        directory : directory where the cache is stored. (default: ./cache)
    
        Return value : data    when cache file is exist and not empty,
                       default otherwise
        """
        if not os.path.isdir(directory):
            return default
        in_path = os.path.join(directory, fname)
        ext1, ext2, fobj = cls.open_autoassess(in_path, 'r')
        if fobj is None:
            return default
        f_size = os.path.getsize(in_path)

        data = default
        if ((ext1 == 'bz2' and f_size > 14) or
            (ext1 == 'gz'  and f_size > 14) or
            (ext1 != 'bz2' and ext1 != 'gz' and f_size > 0)):
            if ext2 == 'yaml' or ext2 == 'YAML':
                #data = yaml.load(fobj)
                data = self.intrinsic_formatter.load_json(fobj,
                                                          parse_float=self.config['json:parse_float'],
                                                          parse_int=self.config['json:parse_int'],
                                                          parse_constant=self.config['json:parse_constant'],
                                                          object_pairs_hook=self.config['json:object_pairs_hook'])
            elif ext2 == 'json'or ext2 == 'JSON':
                # data = json.load(fobj)
                data = self.intrinsic_formatter.load_yaml(fobj)
            else:
                data = fobj.read()
        f.close()
        return data
    

if __name__ == '__main__':
    help(__name__)


