/*
###################################################################
#                                                                 #
#       @description: Proyecto en nodejs para realizar el         #
#                     Account Reconciliation de los usuarios      #
#                                                                 #
#       @author:        bhernandez                                #
#       @since:         Enero 10, 2025                            #
#       @version:       1.0                                       #
#                                                                 #
###################################################################
*/

import dotenv from 'dotenv';
import AccountReconciliation from './account_reconciliation.js';

// Cargar las variables de entorno
dotenv.config();

const environment = new Map([
    ['ACCOUNT_DIR', process.env.ACCOUNT_DIR],
    ['ACCOUNT_NAME', process.env.ACCOUNT_NAME],
    ['SITE_ID', process.env.SITE_ID],
    ['ITEM_ID', process.env.ITEM_ID],
    ['TENANTID_IUVITY', process.env.TENANTID_IUVITY],
    ['CLIENTID_IUVITY', process.env.CLIENTID_IUVITY],
    ['RUNDECKUSER', `Basic ${process.env.RUNDECKUSER}`],
    ['CLIENTSECRET_IUVITY', process.env.CLIENTSECRET_IUVITY]
]);

const date = new Date();
const name = `${date.toLocaleString('en-US', { month: 'short' })}-${date.getDate()}-${date.getFullYear()}_MIA_Users.csv`;
const account = new AccountReconciliation(environment);

async function main() {
    try {
        // Listar el numero de usuarios.
        const data = await account.read();
        console.log('+++    Cantidad de usuarios consultados:', data.length);

        // Leer listado usuarios y escribir archivo .csv.
        await account.write(name, data);
        console.log('+++    Archivo CSV creado exitosamente.');

        // Cargar listado usuarios a Sharepoint.
        const response = await account.upload(environment, name);
        console.log('\n+++  Archivo cargado a Sharepoint.');
        console.log(`Name: ${response.name}`);
        console.log(`URL: ${response.webUrl}`);
    } catch (error) {
        console.error('Error: ', error);
        process.exit(99);
    }
}
main();
