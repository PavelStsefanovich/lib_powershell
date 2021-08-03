
# To call anonymus function (lambda expression), use '&':

& {param($x,$y) $x+$y} 2 5



# Example:

$file = 'file_name'
cat $file | & {begin {'File beginning ->'} process {"line: $_"} end {'-> File end'}}
