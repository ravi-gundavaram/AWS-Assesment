import boto3
import os

# Initialize the SSM client
ssm_client = boto3.client('ssm')

def lambda_handler(event, context):
    parameter_name = os.getenv('PARAMETER_NAME', '/example/parameter')
    
    try:
        # Fetch the parameter value from SSM
        response = ssm_client.get_parameter(Name=parameter_name, WithDecryption=True)
        parameter_value = response['Parameter']['Value']
        
        return {
            'statusCode': 200,
            'body': f"Parameter value: {parameter_value}"
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': f"Error retrieving parameter: {str(e)}"
        }
