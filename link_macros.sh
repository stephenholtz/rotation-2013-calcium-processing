# Link my macros to Fiji (haven't seen if this is how to do this yet...)
echo 'linking Fiji macros'
sp=$(dirname $0)
ln -vfs $sp/*.ijm /Applications/Fiji.app/macros/
