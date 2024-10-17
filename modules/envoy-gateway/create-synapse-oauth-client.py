import synapseclient
import json
syn = synapseclient.login()

client_meta_data = {
    'client_name': '',
    'redirect_uris': [
        ''
    ],
    # 'client_uri': 'https://yourhost.com/index.html',
    # 'policy_uri': 'https://yourhost.com/policy',
    # 'tos_uri': 'https://yourhost.com/terms_of_service',
    'userinfo_signed_response_alg': 'RS256'
}

# Create the client:
client_meta_data = syn.restPOST(uri='/oauth2/client',
                                endpoint=syn.authEndpoint, body=json.dumps(client_meta_data))

client_id = client_meta_data['client_id']

# Generate and retrieve the client secret:
client_id_and_secret = syn.restPOST(uri='/oauth2/client/secret/'+client_id,
                                    endpoint=syn.authEndpoint, body='')

print(client_id_and_secret)
