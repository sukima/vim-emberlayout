" Description: Functions for opening Ember files in windows
" Author: Devin Weaver <suki@tritarget.org>
" License: MIT

function! s:EmberLoadFiles(files)
  only
  exec 'edit ' . a:files.js
  vsplit
  exec 'edit ' . a:files.test
  wincmd h
  if get(a:files, 'template') != '0'
    split
    exec 'edit ' . a:files.template
    wincmd k
  endif
  if get(a:files, 'page') != '0'
    wincmd l
    split
    exec 'edit ' . a:files.page
    wincmd k
    wincmd h
  endif
endfunction

function! s:EmberCoffeeifyFilename(file)
  let coffeefile = fnamemodify(a:file, ':r') . '.coffee'
  if filereadable(coffeefile)
    return coffeefile
  else
    return a:file
  endif
endfunction

function! s:gsub(str,pat,rep) abort
  return substitute(a:str,'\v\C'.a:pat,a:rep,'g')
endfunction

function! s:winshell() abort
  return &shell =~? 'cmd' || exists('+shellslash') && !&shellslash
endfunction

function! s:shellslash(path) abort
  if s:winshell()
    return s:gsub(a:path,'\\','/')
  else
    return a:path
  endif
endfunction

function! s:EmberAutoDetectFiles(file)
  let normalizedFile = s:shellslash(a:file)
  let type = ''
  let relativePath = matchstr(normalizedFile, '\(app\|tests\)/.\+$')
  let prefixOffset = strridx(normalizedFile, relativePath)
  let prefix = strpart(normalizedFile, 0, prefixOffset)
  let parts = split(relativePath, '/')
  let base = remove(parts, 0)

  let filename = remove(parts, -1)
  let filename = fnamemodify(filename, ':t:r')

  let suffixOffset = strridx(filename, '-test')
  if suffixOffset != -1
    let filename = strpart(filename, 0, suffixOffset)
  endif

  if base == 'app'
    let appType = remove(parts, 0)
    if appType == 'templates'
      let appType = remove(parts, 0)
      if appType == 'components'
        let type = 'components'
      else
        let type = 'controllers'
      endif
    elseif appType == 'components'
      let type = 'components'
    else
      let type = appType
    endif
  elseif base == 'tests'
    let testType = remove(parts, 0)
    if testType == 'acceptance'
      let type = 'controllers'
    elseif testType == 'integration' || testType == 'pages'
      if parts[0] == 'components'
        call remove(parts, 0)
        let type = 'components'
      else
        let type = parts[0]
      endif
    else
      let type = parts[0]
    endif
  else
    echohl WarningMsg
    echo 'Unknown Ember entity'
    echohl None
    return
  endif

  call add(parts, filename)
  let fileData = {}

  if type == 'components'
    let fileData.template = prefix . 'app/templates/components/' . join(parts, '/') . '.hbs'
    let fileData.js = <SID>EmberCoffeeifyFilename(prefix . 'app/components/' . join(parts, '/') . '.js')
    let fileData.test = <SID>EmberCoffeeifyFilename(prefix . 'tests/integration/components/' . join(parts, '/') . '-test.js')
    let fileData.page = <SID>EmberCoffeeifyFilename(prefix . 'tests/pages/components/' . join(parts, '/') . '.js')
  elseif type == 'controllers'
    let fileData.template = prefix . 'app/templates/' . join(parts, '/') . '.hbs'
    let fileData.js = <SID>EmberCoffeeifyFilename(prefix . 'app/controllers/' . join(parts, '/') . '.js')
    let fileData.test = <SID>EmberCoffeeifyFilename(prefix . 'tests/acceptance/' . join(parts, '/') . '-test.js')
    let fileData.page = <SID>EmberCoffeeifyFilename(prefix . 'tests/pages/' . join(parts, '/') . '.js')
  else
    let fileData.js = <SID>EmberCoffeeifyFilename(prefix . 'app/' . join(parts, '/') . '.js')
    let fileData.test = <SID>EmberCoffeeifyFilename(prefix . 'tests/unit/' . join(parts, '/') . '-test.js')
  endif

  return fileData
endfunction

function! emberlayout#open(...)
  let file = a:0 >= 1 ? a:1 : bufname('%')
  let fileData = <SID>EmberAutoDetectFiles(file)
  call <SID>EmberLoadFiles(fileData)
endfunction
