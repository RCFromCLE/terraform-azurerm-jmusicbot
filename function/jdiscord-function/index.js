// Import necessary modules and clients
const { Client, Intents } = require('discord.js');
const { ClientSecretCredential } = require('@azure/identity');
const { ComputeManagementClient } = require('@azure/arm-compute');

// Main function that will be triggered
module.exports = async function (context, myTimer) {
    // Import dotenv to handle environment variables
    const dotenv = require('dotenv');
    dotenv.config();

    // Initialize Discord client with specific intents
    const client = new Client({ intents: [Intents.FLAGS.GUILDS, Intents.FLAGS.GUILD_MESSAGES, Intents.FLAGS.GUILD_VOICE_STATES] });

    try {
        await new Promise((resolve, reject) => {
            // Once the client is ready, execute the following
            client.once('ready', async () => {
                try {
                    context.log(`Logged in as ${client.user.tag}!`);

                    // Retrieve environment variables for Azure and Discord configuration
                    const subscriptionId = process.env.SUBSCRIPTION_ID;
                    const resourceGroupName = process.env.RESOURCE_GROUP_NAME;
                    const vmName = process.env.VM_NAME;
                    const generalChannelId = process.env.GENERAL_CHANNEL_ID;
                    const afkChannelId = process.env.AFK_CHANNEL_ID;

                    // Get the first guild (server) the bot is connected to
                    const guild = client.guilds.cache.first();
                    if (!guild) {
                        throw new Error("Guild not found.");
                    }

                    context.log(`Bot connected to guild: ${guild.name}`);

                    // Filter out voice channels and count users, excluding AFK channel
                    const voiceChannels = guild.channels.cache.filter(c => c.type === 'GUILD_VOICE' && c.id !== afkChannelId);
                    let totalUsers = 0;
                    voiceChannels.forEach(channel => totalUsers += channel.members.size);
                    context.log(`Total voice channel users (excluding AFK): ${totalUsers}`);

                    // Create a credential object for Azure SDK
                    const credential = new ClientSecretCredential(
                        process.env.AZURE_TENANT_ID,
                        process.env.AZURE_CLIENT_ID,
                        process.env.AZURE_CLIENT_SECRET
                    );
                    // Initialize the Azure Compute Management client
                    const computeClient = new ComputeManagementClient(credential, subscriptionId);

                    // Check the current state of the VM
                    const vmOnline = await getVMState(computeClient, resourceGroupName, vmName);

                    // Adjusted logic to avoid starting an already running VM
                    if (totalUsers > 0 && vmOnline) {
                        context.log("VM is already running and users are detected in voice channels. No further actions needed.");
                        const channel = await client.channels.fetch(generalChannelId);
                       // await channel.send('VM is already up and running. Enjoy your time!');
                    } else if (totalUsers > 0 && !vmOnline) {
                        context.log("Users detected in voice channels, starting VM...");
                        await manageVM('start', computeClient, resourceGroupName, vmName);
                        const channel = await client.channels.fetch(generalChannelId);
                        await channel.send('The music bot is spinning up! Get ready to jam!');
                    } else if (totalUsers === 0 && vmOnline) {
                        context.log("No users detected in voice channels, stopping VM...");
                        await manageVM('stop', computeClient, resourceGroupName, vmName);
                        const channel = await client.channels.fetch(generalChannelId);
                        await channel.send('All quiet on the voice channels. The music bot is taking a break!');
                    }

                    resolve();
                } catch (error) {
                    context.log.error(`Error: ${error.message}`);
                    reject(error);
                }
            });

            // Handle Discord client errors
            client.on('error', (error) => {
                context.log.error(`Discord client error: ${error}`);
                reject(error);
            });

            // Log in to the Discord client using the bot token
            client.login(process.env.DISCORD_BOT_TOKEN);
        });
    } catch (error) {
        context.log.error(`An error occurred: ${error.message}`);
    }
};

// Function to get the current power state of the Azure VM
async function getVMState(computeClient, resourceGroupName, vmName) {
    const vm = await computeClient.virtualMachines.get(resourceGroupName, vmName, { expand: 'instanceView' });
    const powerState = vm.instanceView.statuses.find(status => status.code.startsWith('PowerState/')).code;
    return powerState.endsWith('running');
}

// Function to start or stop the Azure VM based on the action parameter
async function manageVM(action, computeClient, resourceGroupName, vmName) {
    if (action === 'start') {
        await computeClient.virtualMachines.beginStart(resourceGroupName, vmName);
    } else if (action === 'stop') {
        await computeClient.virtualMachines.beginDeallocate(resourceGroupName, vmName);
    }
}
