ICS_CONNECTION_URL=$1
OIC_USERNAME=$2
OIC_PASS=$3

replaceuser=$4

if [ -f "user_accounts.txt" ]
        then
           rm user_accounts.txt
    fi
	if [ -f "connections.txt" ]
        then
           rm connections.txt
    fi

 #curl -k -v -X GET -u $OIC_USERNAME:$OIC_PASS -H Accept:application/json  $ICS_CONNECTION_URL/ic/api/integration/v1/connections?q={status:%27CONFIGURED%27} -o curl_result 2>&1 | tee curl_output
     curl -G -X GET -u $OIC_USERNAME:$OIC_PASS -H "Accept:application/json" --data-urlencode "q={status:  'CONFIGURED'}"  $ICS_CONNECTION_URL/ic/api/integration/v1/connections -o curl_result 2>&1 | tee curl_output
    Integr_count=$(jq '.items | length' curl_result )
	for ((i=0; i < $Integr_count; i++))
               do
                err_message=""
               #Obtain the Integration artifacts from file
               id=$( jq -r '.items['$i'] | .id' curl_result )          	  
			  
			 curl -X GET -u $OIC_USERNAME:$OIC_PASS -H "Accept:application/json" $ICS_CONNECTION_URL/ic/api/integration/v1/connections/$id	-o curl_result_conn 2>&1 | tee curl_output_conn
           	 name=$( jq -r '.securityProperties[0] | .propertyName' curl_result_conn )
		     value=$( jq -r '.securityProperties[0] | .propertyValue' curl_result_conn )
            
			echo "$id | $name | $value">>user_accounts.txt			 	
		  if [ "$value" == "$replaceuser" ]	
			then
			curl   -X POST  -u $OIC_USERNAME:$OIC_PASS -H "X-HTTP-Method-Override:PATCH" -H "Content-Type:application/json" -d @CONN.json $ICS_CONNECTION_URL/ic/api/integration/v1/connections/$id -o "curl_result_conn_$id" | tee "curl_output_conn_$id"
              # filenm=curl_output_conn_$id
             int_status=$( cat "curl_result_conn_$id" | jq -r .status ) 
    echo "*********$id   $int_status*********"
          if [ "$int_status" == 'CONFIGURED' ] 
		  then
			   echo "Connection Activated successfully"
			   echo "$id | SUCCESS" >>connections.txt
		  else
			   echo "Failed while Updating the connection"
               echo "$id | FAILURE" >>connections.txt

          fi
		fi
				
		done	

echo "*******************DONE !!!****************"

