#!/usr/bin/env python3
"""
Modern Python REPL Configuration
Enhanced interactive Python experience with modern tools and utilities
"""

import sys
import os

# =====================================================
# Basic Setup
# =====================================================

# Enable UTF-8 encoding
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')
    sys.stderr.reconfigure(encoding='utf-8')

# Add current directory to path for convenience
if '' not in sys.path:
    sys.path.insert(0, '')

# =====================================================
# History and Completion
# =====================================================

def setup_history():
    """Setup command history with better defaults"""
    try:
        import readline
        import atexit
        
        # History file location
        history_file = os.path.expanduser('~/.python_history')
        
        # Read existing history
        try:
            readline.read_history_file(history_file)
        except FileNotFoundError:
            pass
        
        # Set history length
        readline.set_history_length(10000)
        
        # Save history on exit
        atexit.register(readline.write_history_file, history_file)
        
        # Enable tab completion
        readline.parse_and_bind('tab: complete')
        
        # Vi-style editing (comment out for emacs style)
        # readline.parse_and_bind('set editing-mode vi')
        
        return True
    except ImportError:
        return False

def setup_completion():
    """Enhanced tab completion"""
    try:
        import readline
        import rlcompleter
        
        # Smart completion
        if 'libedit' in readline.__doc__:
            readline.parse_and_bind("bind ^I rl_complete")
        else:
            readline.parse_and_bind("tab: complete")
        
        # Case-insensitive completion
        readline.parse_and_bind('set completion-ignore-case on')
        
        # Show all completions immediately
        readline.parse_and_bind('set show-all-if-ambiguous on')
        
    except ImportError:
        pass

# Setup history and completion
setup_history()
setup_completion()

# =====================================================
# Pretty Printing and Display
# =====================================================

def setup_pretty_printing():
    """Enhanced output formatting"""
    try:
        import pprint
        
        # Better default repr for containers
        def pretty_repr(obj):
            if isinstance(obj, (list, tuple, dict, set)):
                return pprint.pformat(obj, width=120, depth=4)
            return repr(obj)
        
        # Install as display hook
        def pretty_display_hook(obj):
            if obj is not None:
                try:
                    # Try rich first if available
                    from rich.console import Console
                    from rich.pretty import Pretty
                    console = Console()
                    console.print(Pretty(obj))
                except ImportError:
                    # Fallback to pprint
                    if isinstance(obj, (list, tuple, dict, set)):
                        pprint.pprint(obj, width=120)
                    else:
                        print(repr(obj))
        
        sys.displayhook = pretty_display_hook
        
    except ImportError:
        pass

setup_pretty_printing()

# =====================================================
# Useful Imports and Functions
# =====================================================

# Common imports for convenience
import json
import re
import sys
import os
from datetime import datetime, timedelta
from pathlib import Path
from collections import defaultdict, Counter, namedtuple
from functools import partial, reduce
from itertools import chain, combinations, permutations

# Try to import commonly used libraries
try:
    import requests
except ImportError:
    pass

try:
    import pandas as pd
    import numpy as np
except ImportError:
    pass

# =====================================================
# Utility Functions
# =====================================================

def ls(path='.'):
    """List directory contents"""
    path = Path(path)
    if path.is_dir():
        return list(path.iterdir())
    return []

def pwd():
    """Print working directory"""
    return Path.cwd()

def cd(path):
    """Change directory"""
    os.chdir(path)
    return Path.cwd()

def cat(filename):
    """Read file contents"""
    return Path(filename).read_text()

def grep(pattern, text):
    """Simple grep functionality"""
    if isinstance(text, str):
        lines = text.split('\n')
    else:
        lines = text
    return [line for line in lines if re.search(pattern, line)]

def json_pp(obj):
    """Pretty print JSON"""
    if isinstance(obj, str):
        obj = json.loads(obj)
    print(json.dumps(obj, indent=2, ensure_ascii=False))

def timeit(func, *args, **kwargs):
    """Simple timing function"""
    import time
    start = time.time()
    result = func(*args, **kwargs)
    end = time.time()
    print(f"Execution time: {end - start:.4f} seconds")
    return result

def sizeof(obj):
    """Get size of object in memory"""
    import sys
    return sys.getsizeof(obj)

def type_info(obj):
    """Detailed type information"""
    info = {
        'type': type(obj).__name__,
        'module': type(obj).__module__,
        'size': sizeof(obj),
        'methods': [m for m in dir(obj) if not m.startswith('_')],
    }
    
    if hasattr(obj, '__len__'):
        info['length'] = len(obj)
    
    return info

def reload_module(module):
    """Reload a module"""
    import importlib
    return importlib.reload(module)

# =====================================================
# Development Helpers
# =====================================================

def debug():
    """Start debugger"""
    import pdb
    pdb.set_trace()

def profile(func, *args, **kwargs):
    """Profile a function"""
    import cProfile
    import pstats
    from io import StringIO
    
    pr = cProfile.Profile()
    pr.enable()
    result = func(*args, **kwargs)
    pr.disable()
    
    s = StringIO()
    ps = pstats.Stats(pr, stream=s).sort_stats('cumulative')
    ps.print_stats()
    print(s.getvalue())
    
    return result

def inspect_obj(obj):
    """Detailed object inspection"""
    import inspect
    
    print(f"Object: {obj}")
    print(f"Type: {type(obj)}")
    print(f"Module: {getattr(type(obj), '__module__', 'N/A')}")
    print(f"Doc: {getattr(obj, '__doc__', 'No documentation')}")
    
    if hasattr(obj, '__dict__'):
        print(f"Attributes: {list(obj.__dict__.keys())}")
    
    print(f"Methods: {[m for m in dir(obj) if callable(getattr(obj, m)) and not m.startswith('_')]}")

# =====================================================
# Interactive Helpers  
# =====================================================

def help_commands():
    """Show available custom commands"""
    commands = {
        'ls(path)': 'List directory contents',
        'pwd()': 'Print working directory', 
        'cd(path)': 'Change directory',
        'cat(file)': 'Read file contents',
        'grep(pattern, text)': 'Search for pattern in text',
        'json_pp(obj)': 'Pretty print JSON',
        'timeit(func, *args)': 'Time function execution',
        'sizeof(obj)': 'Get object size in memory',
        'type_info(obj)': 'Detailed type information',
        'reload_module(mod)': 'Reload a module',
        'debug()': 'Start debugger',
        'profile(func, *args)': 'Profile function execution',
        'inspect_obj(obj)': 'Detailed object inspection'
    }
    
    print("Available custom commands:")
    for cmd, desc in commands.items():
        print(f"  {cmd:<25} - {desc}")

# Add help command to builtins for easy access
import builtins
builtins.help_commands = help_commands

# =====================================================
# Startup Message
# =====================================================

def show_startup_info():
    """Show Python REPL startup information"""
    python_version = f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}"
    
    print(f"🐍 Modern Python {python_version} REPL")
    print(f"📁 Working directory: {os.getcwd()}")
    
    # Show available enhancements
    enhancements = []
    
    try:
        import readline
        enhancements.append("readline")
    except ImportError:
        pass
    
    try:
        from rich.console import Console
        enhancements.append("rich")
    except ImportError:
        pass
        
    try:
        import requests
        enhancements.append("requests")
    except ImportError:
        pass
        
    try:
        import pandas
        enhancements.append("pandas/numpy")
    except ImportError:
        pass
    
    if enhancements:
        print(f"✨ Available: {', '.join(enhancements)}")
    
    print("💡 Type 'help_commands()' for custom utilities")
    print()

# Show startup info
show_startup_info()

# =====================================================
# Cleanup
# =====================================================

# Clean up namespace
del setup_history, setup_completion, setup_pretty_printing, show_startup_info