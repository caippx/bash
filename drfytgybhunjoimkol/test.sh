function go1(){
echo $1
}
function go2(){
echo $1
}
function go3(){
echo $1
}

[[ -n $1 ]] && go1 $1
[[ -n $2 ]] && go2 $2
[[ -n $3 ]] && go3 $3
