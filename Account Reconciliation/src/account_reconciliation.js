import fs from 'fs';
import readline from 'readline';
import 'isomorphic-fetch'
import { createObjectCsvWriter } from 'csv-writer';
import { ClientSecretCredential } from '@azure/identity'
import { TokenCredentialAuthenticationProvider } from '@microsoft/microsoft-graph-client/authProviders/azureTokenCredentials/index.js'
import { Client } from '@microsoft/microsoft-graph-client'

class AccountReconciliation {
    constructor(environment) {
        this.account_dir = environment.get('ACCOUNT_DIR');
        this.account_name = environment.get('ACCOUNT_NAME');
        this.siteId = environment.get('SITE_ID');
        this.itemId = environment.get('ITEM_ID');
        this.tenantId_iuvity = environment.get('TENANTID_IUVITY');
        this.clientId_iuvity = environment.get('CLIENTID_IUVITY');
        this.clientSecret_iuvity = environment.get('CLIENTSECRET_IUVITY');
    }

    async read() {
        const users = [];
        const rl = readline.createInterface({
            input: fs.createReadStream(`${this.account_dir}/${this.account_name}`),
            output: process.stdout,
            terminal: false
        });

        for await (const line of rl) {
            const [user, host] = line.split(',').map(item => item.trim());
            users.push({ user, host });
        }
        return users;
    }

    async write(name, data) {
        const csvWriter = createObjectCsvWriter({
            path: `${this.account_dir}/${name}`,
            header: [
                { id: 'user', title: 'Usuario' },
                { id: 'host', title: 'Hostname' }
            ]
        });
        await csvWriter.writeRecords(data);
    }

    async upload(environment, name) {
        const date = new Date();
        const year = date.getFullYear();
        const month = date.toLocaleString('en-US', { month: 'long' });
        const credential = new ClientSecretCredential(this.tenantId_iuvity, this.clientId_iuvity, this.clientSecret_iuvity);
        const authProvider = new TokenCredentialAuthenticationProvider(credential, { scopes: ['https://graph.microsoft.com/.default'] });
        const client = Client.initWithMiddleware({
            debugLogging: false,
            authProvider,
            defaultVersion: 'v1.0'
        })
        const fileStream = await fs.promises.readFile(`${this.account_dir}/${name}`, { encoding: 'utf-8' });
        return client.api(`/sites/${this.siteId}/drive/items/${this.itemId}:/${year}/PROCESOS AUTOMATIZADOS/DataCenter/${month}/${name}:/content`).put(fileStream);
    }
}

export default AccountReconciliation;
