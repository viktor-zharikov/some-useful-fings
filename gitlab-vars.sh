 #!/bin/bash
token="" #gitlab token for api
prefix=""               #additional prefix for variables
file="VARIABLE_BACKEND.txt"        #file with variables
project=""         #project in gitlab

work_cycle(){                      # work-cycle
cat $file | while read line; do
key=$(echo $line |awk -F\:\  '{print$1}')
value=$(echo $line |awk -F\:\  '{print$2}')
eval $1
done
}

ahtung(){
while true; do
read  -p $'ВВЕДИТЕ y|Y для подтвержения операции\n' confirm
[[ "$confirm" == "y" || "$confirm" == "Y" ]] && { sleep 10; return 0; }
done
}

while true; do
read  -p $'Введите желамое действие\n0 - сгенерировать список переменных с префиксом\n1 - отправить переменные в проект\n2 - обновить существующие переменные\n3 - удалить переменные\n4 - получить все переменные из проекта\n' Keypress
[[ "$Keypress" != "test" || "$Keypress" -le 5 ]] && break
done

if [[ "$Keypress" == "0" ]]; then
work_cycle 'echo "  $key: \"\$$prefix$key\"" >> configmap_$prefix.txt'                 #generage variables with prefix
fi

if [[ $Keypress == "1" ]]; then
#work_cycle 'echo "curl --header "PRIVATE-TOKEN: $token" "https://gitlab.com/api/v4/projects/$project/variables" --form "key=$prefix$key" --form "value=$value""'
work_cycle 'curl --request POST --header "PRIVATE-TOKEN: $token" "https://gitlab.com/api/v4/projects/$project/variables" --form "key=$prefix$key" --form "value=$value"' # add variables
fi

if [[ $Keypress == "2" ]]; then
echo -e "`cat $file`\e[1;31m\nAHTUNG UPDATE VARIABLE PLEAS WAIT\e[0m"
ahtung
work_cycle 'curl --request PUT --header "PRIVATE-TOKEN: $token" "https://gitlab.com/api/v4/projects/$project/variables/$prefixkey" --form "value=$value"' # update variables value
fi
if [[ $Keypress == "3" ]]; then
echo -e "`cat $file`\e[1;31m\nAHTUNG DELETED VARIABLE PLEAS WAIT\e[0m"
ahtung
work_cycle 'curl --request DELETE --header "PRIVATE-TOKEN: $token" "https://gitlab.com/api/v4/projects/$project/variables/$prefix$key"' # delete vars
fi

if [[ $Keypress == "4" ]]; then
pages=$(curl -s --head --header "PRIVATE-TOKEN: $token" "https://gitlab.com/api/v4/projects/$project/variables?per_page=100" | grep "x-total-pages:" | awk -F:\  '{print$2}' | tr -d $'\r')
for (( i = 1; i <= $pages; i++ )); do
curl -s --header "PRIVATE-TOKEN: $token" "https://gitlab.com/api/v4/projects/$project/variables?per_page=100&page=$i" | jq -M -r '.[] | "\(.key): \(.value)" ' >> ALL_VARIABLE.txt
[[ `echo $?` -eq 0 ]] && echo "Скачано страниц с переменными $i из $pages" || "При скачивании страницы $i произошла ошибка"; 
done
fi
