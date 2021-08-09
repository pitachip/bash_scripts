#!/usr/bin/env bash 

#script to stop the nat-gateway to save on cost for the dev environment 

#exit the script if we get a non 0 status code on a return 
set -e

nat_gateway=""
state=""
status=""

function get_nat_gateway () {
    nat_gateway=$(aws ec2 describe-nat-gateways --filter "Name=tag:Name,Values=dev" "Name=state,Values=available" \
--query 'NatGateways[].NatGatewayId' --output text --profile pitachip-rend)

}

function get_nat_status () {
    aws ec2 describe-nat-gateways --filter "Name=tag:Name,Values=dev" "Name=state,Values=deleting" --query 'NatGateways[].State' --output text --profile pitachip-rend
}

function delete_nat_gateway () {
    aws ec2 delete-nat-gateway --nat-gateway-id $nat_gateway --profile pitachip-rend
}

function wait_for_deletion () {
    status=$(get_nat_status)
    while [ $status != "deleted" ]
    do 
        echo "nat gateway is not yet deleted"
        sleep 5 
        status=$(get_nat_status)
    done
}

function delete_blackhole_route () {
    aws ec2 delete-route --route-table-id rtb-052eb477eaa7e0704 --destination-cidr-block 0.0.0.0/0 --profile pitachip-rend
}

echo "Getting the nat gateway id..."
get_nat_gateway
echo "Deleting nat gateway..."
delete_nat_gateway
echo "Waiting for nat gateway to be deleted..."
wait_for_deletion;
echo "Nat gateway deleted!"
delete_blackhole_route
echo "Deleted black hole route"


