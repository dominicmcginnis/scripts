#!/bin/bash

# Install NPM packages that are not already installed
function install_package_if_needed() {
    local p=${1:-Package required}
    local v=${2:-Version required}
    if [[ ! -e "./node_modules/$p/package.json" ]]; then
		npm install "$p@$v"
	else
    	local i=$(node -p "require('$p/package.json').version")
	    [ "$i" == "$v" ] || npm install "$p@$v"
	fi
}

declare -a modulesArray=$(node -e "var o = require('./package.json').devDependencies; for (var p in o) { console.log(p + '@' + o[p]); }")

for i in ${modulesArray[@]}; do
        package=$(echo $i | perl -pe 's/@/ /g')
        install_package_if_needed ${package}
done
