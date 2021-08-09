#!/usr/bin/env bash 

#script to start the nat-gateway for the dev environment 

#exit the script if we get a non 0 status code on a return 
set -e

nat_gateway=""
state=""
status=""

function create_nat_gateway () {
    aws ec2 create-nat-gateway --subnet-id subnet-08fa0ded9af839c5e --allocation-id eipalloc-04c0599ad59aaae09 --tag-specifications 'ResourceType=natgateway,Tags=[{Key=Name, Value=dev}]' --profile pitachip-rend
}

function get_nat_status () {
    aws ec2 describe-nat-gateways --filter "Name=tag:Name,Values=dev" "Name=state,Values=pending" --query 'NatGateways[].State' --output text --profile pitachip-rend
}

function wait_for_creation () {
    status=$(get_nat_status)
    while [ $status != "available" ]
    do 
        echo "nat gateway is not yet created"
        sleep 5 
        status=$(get_nat_status)
    done
}

function add_route () {
    #get nat gateway id
    nat_gateway=$(aws ec2 describe-nat-gateways --filter "Name=tag:Name,Values=dev" "Name=state,Values=available" \
    --query 'NatGateways[].NatGatewayId' --output text --profile pitachip-rend)

    #set up route to the gateway
    aws ec2 create-route --route-table-id rtb-052eb477eaa7e0704 --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $nat_gateway --profile pitachip-rend
}

echo "Creating nat gateway..."
create_nat_gateway
echo "Waiting for nat gateway to be created..."
wait_for_creation;
echo "Nat gateway created!"
echo "Creating route for gateway..."
add_route
echo "Route created!"  


