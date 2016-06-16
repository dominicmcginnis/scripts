#!/bin/bash

# Install NPM packages that are not already installed
function install_package_if_needed() {
    local p=${1:-Package required}
    local v=${2:-Version required}
    # Use this for version comps as it won't contain the special npm chars
    local compV=$(echo $v | perl -pe 's/~//g; s/\^//g')
    if [[ ! -e "./node_modules/$p/package.json" ]]; then
		npm install "$p@$v"
	else
    	local i=$(node -p "require('$p/package.json').version")
	    if [[ ! "$i" == "$compV" ]]; then
	    	 npm install "$p@$v"
	    fi
	fi
}

declare -a modulesArray=$(node -e "var o = require('./package.json').devDependencies; for (var p in o) { console.log(p + '_-_' + o[p]); }")

for i in ${modulesArray[@]}; do
        package=$(echo $i | perl -pe 's/_-_/ /g')
        install_package_if_needed ${package}
done
