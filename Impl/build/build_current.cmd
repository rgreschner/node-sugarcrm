md current
cmd /C cake.cmd build
md current\lib
md current\node_modules
md current\node_modules\node-sugarcrm
move current\app.js current\lib\node-sugarcrm.js
copy ..\redist\*.* current
move current\package.json current\node_modules\node-sugarcrm\package.json
move current\lib current\node_modules\node-sugarcrm\lib
