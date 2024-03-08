const { Client, Intents } = require('discord.js');
const { ClientSecretCredential } = require('@azure/identity');
const { ComputeManagementClient } = require('@azure/arm-compute');

module.exports = async function (context, myTimer) {
    const dotenv = require('dotenv');
    dotenv.config();

    const client = new Client({ intents: [Intents.FLAGS.GUILDS, Intents.FLAGS.GUILD_MESSAGES] });

    try {
        await new Promise((resolve, reject) => {
            client.once('ready', async () => {
                try {
                    context.log(`Logged in as ${client.user.tag}!`);

                    const subscriptionId = process.env.SUBSCRIPTION_ID;
                    const resourceGroupName = process.env.RESOURCE_GROUP_NAME;
                    const vmName = process.env.VM_NAME;
                    const generalChannelId = process.env.GENERAL_CHANNEL_ID;
                    const afkChannelId = process.env.AFK_CHANNEL_ID;

                    const guild = client.guilds.cache.first();
                    if (!guild) {
                        throw new Error("Guild not found.");
                    }

                    context.log(`Bot connected to guild: ${guild.name}`);

                    const voiceChannels = guild.channels.cache.filter(c => c.type === 'GUILD_VOICE' && c.id !== afkChannelId);
                    let totalUsers = 0;
                    voiceChannels.forEach(channel => totalUsers += channel.members.size);
                    context.log(`Total voice channel users (excluding AFK): ${totalUsers}`);

                    const credential = new ClientSecretCredential(
                        process.env.AZURE_TENANT_ID,
                        process.env.AZURE_CLIENT_ID,
                        process.env.AZURE_CLIENT_SECRET
                    );
                    const computeClient = new ComputeManagementClient(credential, subscriptionId);

                    const vmOnline = await getVMState(computeClient, resourceGroupName, vmName);

                    if (totalUsers > 0 && !vmOnline) {
                        context.log("Users detected in voice channels, starting VM...");
                        await manageVM('start', computeClient, resourceGroupName, vmName);
                        const channel = await client.channels.fetch(generalChannelId);
                        await channel.send('The music bot is spinning up! Get ready to jam!');
                    } else if (totalUsers === 0 && vmOnline) {
                        context.log("No users detected in voice channels, stopping VM...");
                        await manageVM('stop', computeClient, resourceGroupName, vmName);
                        const channel = await client.channels.fetch(generalChannelId);
                        await channel.send('All quiet on the voice channels. The music bot is taking a break!');
                        client.destroy(); // Destroy the client only when no users are in voice channels.
                    }

                    resolve();
                } catch (error) {
                    context.log.error(`Error: ${error.message}`);
                    reject(error);
                }
            });

            client.on('error', (error) => {
                context.log.error(`Discord client error: ${error}`);
                reject(error);
            });

            client.login(process.env.DISCORD_BOT_TOKEN);
        });
    } catch (error) {
        context.log.error(`An error occurred: ${error.message}`);
    }
};

async function getVMState(computeClient, resourceGroupName, vmName) {
    const vm = await computeClient.virtualMachines.get(resourceGroupName, vmName, { expand: 'instanceView' });
    const powerState = vm.instanceView.statuses.find(status => status.code.startsWith('PowerState/')).code;
    return powerState.endsWith('running');
}

async function manageVM(action, computeClient, resourceGroupName, vmName) {
    if (action === 'start') {
        await computeClient.virtualMachines.beginStart(resourceGroupName, vmName);
    } else if (action === 'stop') {
        await computeClient.virtualMachines.beginDeallocate(resourceGroupName, vmName);
    }
}
