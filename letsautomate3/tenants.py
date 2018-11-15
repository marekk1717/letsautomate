import fire
import getpass
import sys
import json
import base64
import os.path
from cvpysdk.commcell import Commcell

enckey = 'Erdfsderw5245sdfdfDfgd'
cvauthfile = 'cvauth.json'

def encode(key, clear):
    enc = []
    for i in range(len(clear)):
        key_c = key[i % len(key)]
        enc_c = chr((ord(clear[i]) + ord(key_c)) % 256)
        enc.append(enc_c)
    return base64.urlsafe_b64encode("".join(enc).encode()).decode()

def decode(key, enc):
    dec = []
    enc = base64.urlsafe_b64decode(enc).decode()
    for i in range(len(enc)):
        key_c = key[i % len(key)]
        dec_c = chr((256 + ord(enc[i]) - ord(key_c)) % 256)
        dec.append(dec_c)
    return "".join(dec)

def create_authfile():
    webconsole_hostname = input("Webconsole URL: ")
    commcell_username = input("Username: ")
    commcell_password = encode(enckey, getpass.getpass("Password for " + commcell_username + ": "))

    json_str = {}
    json_str['username'] = commcell_username
    json_str['password'] = commcell_password
    json_str['consoleurl'] = webconsole_hostname

    with open('cvauth.json', 'w') as outfile:
        json.dump(json_str, outfile)

def login():

    auth_read = False
    if os.path.isfile(cvauthfile):
        authdata = json.load(open(cvauthfile))
        if 'username' in authdata and 'password' in authdata and 'consoleurl' in authdata:
            commcell_username = authdata['username']
            commcell_password = decode(enckey, authdata['password'])
            webconsole_hostname = authdata['consoleurl']
            auth_read = True

    if not auth_read:
        webconsole_hostname = input("Username: ")
        commcell_username = input("Username: ")
        commcell_password = getpass.getpass("Password for " + commcell_username + ": ")

    try:
        commcell = Commcell(webconsole_hostname, commcell_username, commcell_password)
    except BaseException as e:
        print(str(e))
        sys.exit(1)
#    print('User ' + commcell_username + ' logged in successfully on ' + commcell.commserv_name + '.')
    return commcell

def create_tenant(company, contact_name, email, companyalias, plans, proxy):

    if plans.lower() == 'none':
        nplans = None
    else:
        if isinstance(plans, tuple):
            nplans = list(plans)
        else:
            nplans = plans.split(',')

    ncommcell = login()

    try:
        newtenant = ncommcell.organizations.add(name=company, email=email, contact_name=contact_name, company_alias=companyalias)
    except BaseException as e:
        print(str(e))
        sys.exit(1)
    print('Tenant ' + company + ' has been added successfully.')

    if plans.lower() != "none":
        try:
            newtenant.plans = nplans
        except BaseException as e:
            print(str(e))
            sys.exit(1)
        print('Plans ' + plans + ' have been successfully assigned to ' + company + '.')

    if proxy.lower() == 'none':
        print('No change has been made in existing firewall configuration.')
    else:
        proxycfg = proxy.split(',')
        ngroup = ncommcell.client_groups.get(company)
        commserve = ncommcell.clients.get(ncommcell.commserv_name)

        if len(proxycfg) == 1:
            try:
                ngroup.network.set_outgoing_routes([{'routeType': 'VIA_PROXY', 'remoteEntity': ncommcell.commserv_name,
                                                     'remoteProxy': proxycfg[0], 'isClient': True}])
                ngroup.network.set_incoming_connections([{'state': 'BLOCKED','entity': proxycfg[0],'isClient': True}])
                commserve.network.set_outgoing_routes([{'routeType': 'VIA_PROXY', 'remoteEntity': company,
                                                     'remoteProxy': proxycfg[0], 'isClient': False}])
                commserve.push_network_config()
                ngroup.push_network_config()

            except BaseException as e:
                print(str(e))
                sys.exit(1)

        if len(proxycfg) == 3:
            try:
                ngroup.network.set_outgoing_routes([{'routeType': 'VIA_GATEWAY', 'remoteEntity': proxycfg[0],
                                                     'streams': 1, 'gatewayPort': int(proxycfg[2]), 'gatewayHost': proxycfg[1],
                                                     'isClient': True, 'forceAllDataTraffic': True, 'connectionProtocol': 1}])
                ngroup.network.set_outgoing_routes([{'routeType': 'VIA_PROXY', 'remoteEntity': ncommcell.commserv_name,
                                                     'remoteProxy': proxycfg[0], 'isClient': True}])
                ngroup.network.set_incoming_connections([{'state': 'BLOCKED', 'entity': proxycfg[0], 'isClient': True}])
                commserve.network.set_outgoing_routes([{'routeType': 'VIA_PROXY', 'remoteEntity': company,
                                                     'remoteProxy': proxycfg[0], 'isClient': False}])
                commserve.push_network_config()
            except BaseException as e:
                print(str(e))
                sys.exit(1)
        if len(proxycfg) == 6:
            try:
                ngroup.network.set_outgoing_routes([{'routeType': 'VIA_GATEWAY', 'remoteEntity': proxycfg[0],
                                                     'streams': 1, 'gatewayPort': int(proxycfg[2]), 'gatewayHost': proxycfg[1],
                                                     'isClient': True, 'forceAllDataTraffic': True, 'connectionProtocol': 1}])
                ngroup.network.set_outgoing_routes([{'routeType': 'VIA_PROXY', 'remoteEntity': ncommcell.commserv_name,
                                                     'remoteProxy': proxycfg[0], 'isClient': True}])
                ngroup.network.set_incoming_connections([{'state': 'BLOCKED', 'entity': proxycfg[0], 'isClient': True}])
                commserve.network.set_outgoing_routes([{'routeType': 'VIA_PROXY', 'remoteEntity': company,
                                                     'remoteProxy': proxycfg[0], 'isClient': False}])

                ngroup.network.set_outgoing_routes([{'routeType': 'VIA_GATEWAY', 'remoteEntity': proxycfg[3],
                                                     'streams': 1, 'gatewayPort': int(proxycfg[5]),
                                                     'gatewayHost': proxycfg[4],
                                                     'isClient': True, 'forceAllDataTraffic': True,
                                                     'connectionProtocol': 1}])
                ngroup.network.set_outgoing_routes([{'routeType': 'VIA_PROXY', 'remoteEntity': ncommcell.commserv_name,
                                                     'remoteProxy': proxycfg[3], 'isClient': True}])
                ngroup.network.set_incoming_connections([{'state': 'BLOCKED', 'entity': proxycfg[3], 'isClient': True}])
                commserve.network.set_outgoing_routes([{'routeType': 'VIA_PROXY', 'remoteEntity': company,
                                                        'remoteProxy': proxycfg[3], 'isClient': False}])
                commserve.push_network_config()
            except BaseException as e:
                print(str(e))
                sys.exit(1)
        print('Firewall options have been configured successfully.')


def delete_tenants(companies):
    ncommcell = login()

    if isinstance(companies, tuple):
        ncompanies = companies
    else:
        ncompanies = companies.split(',')

    for x in range(0, len(ncompanies)):
        try:
            nplans = []
            ncommcell.organizations.get(ncompanies[x]).plans = nplans
            ncommcell.organizations.delete(ncompanies[x])
        except BaseException as e:
            print(str(e))
            sys.exit(1)
        print('Tenant ' + ncompanies[x] + ' has been deleted successfully.')


def disable_activity(companies):
    ncommcell = login()

    if isinstance(companies, tuple):
        ncompanies = companies
    else:
        ncompanies = companies.split(',')

    for x in range(0, len(ncompanies)):
        try:
            ngroup = ncommcell.client_groups.get(ncompanies[x])
            ngroup.disable_backup()
            ngroup.disable_restore()
        except BaseException as e:
            print(str(e))
            sys.exit(1)
        print('Backup/Restore activities have been disabled successfully on Tenant: ' + ncompanies[x] + '.')

def enable_activity(companies):
    ncommcell = login()

    if isinstance(companies, tuple):
        ncompanies = companies
    else:
        ncompanies = companies.split(',')

    for x in range(0, len(ncompanies)):
        try:
            ngroup = ncommcell.client_groups.get(ncompanies[x])
            ngroup.enable_backup()
            ngroup.enable_restore()
        except BaseException as e:
            print(str(e))
            sys.exit(1)
        print('Backup/Restore activities have been disabled successfully on Tenant: ' + ncompanies[x] + '.')

def release_license(companies):
    ncommcell = login()

    if isinstance(companies, tuple):
        ncompanies = companies
    else:
        ncompanies = companies.split(',')

    for x in range(0, len(ncompanies)):
        try:
            ngroup = ncommcell.client_groups.get(ncompanies[x])
            for ncl in ngroup.associated_clients:
                try:
                    nclient = ncommcell.clients.get(ncl)
                    nclient.release_license()
                except BaseException as e:
                    print(str(e))
                else:
                    print('Licenses have been released on ' + nclient.client_name + '.')


        except BaseException as e:
            print(str(e))
            sys.exit(1)

def delete_clients(companies):
    ncommcell = login()

    if isinstance(companies, tuple):
        ncompanies = companies
    else:
        ncompanies = companies.split(',')

    for x in range(0, len(ncompanies)):
        try:
            ngroup = ncommcell.client_groups.get(ncompanies[x])
            for ncl in ngroup.associated_clients:
                try:
                    ncommcell.clients.delete(ncl)
                except BaseException as e:
                    print(str(e))
                else:
                    print(ncl + ' have been deleted successfully.')

        except BaseException as e:
            print(str(e))
            sys.exit(1)

def list_tenants():
    ncommcell = login()

    try:
        for company in ncommcell.organizations.all_organizations:
            print(company)
    except BaseException as e:
        print(str(e))
        sys.exit(1)

if __name__ == '__main__':
  fire.Fire()
