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
            client.once('ready', async () => {
                try {
                    context.log(`Logged in as ${client.user.tag}!`);

                    // Retrieve environment variables for Azure and Discord configuration
                    const subscriptionId = process.env.SUBSCRIPTION_ID;
                    const resourceGroupName = process.env.RESOURCE_GROUP_NAME;
                    const vmName = process.env.VM_NAME;
                    const generalChannelId = process.env.GENERAL_CHANNEL_ID;
                    const afkChannelId = process.env.AFK_CHANNEL_ID;
                    const musicChannelId = process.env.MUSIC_CHANNEL_ID; // Add MUSIC_CHANNEL_ID to your .env

                    // Get the first guild (server) the bot is connected to
                    const guild = client.guilds.cache.first();
                    if (!guild) {
                        throw new Error("Guild not found.");
                    }

                    context.log(`Bot connected to guild: ${guild.name}`);

                    // Filter out voice channels and count users, excluding AFK and non-music channels
                    const voiceChannels = guild.channels.cache.filter(c => c.type === 'GUILD_VOICE' && c.id !== afkChannelId);
                    let totalUsers = 0;
                    let musicChannelActive = false;

                    voiceChannels.forEach(channel => {
                        if (channel.id === musicChannelId) {
                            if (channel.members.size > 0) {
                                musicChannelActive = true;
                            }
                        }
                        totalUsers += channel.members.size;
                    });

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

                    const generalChannel = await client.channels.fetch(generalChannelId);

                    // Logic for starting/stopping the VM based on the music channel activity or command
                    if (musicChannelActive && !vmOnline) {
                        context.log("Users detected in the music channel, starting VM...");
                        await manageVM('start', computeClient, resourceGroupName, vmName);
                        await generalChannel.send('The band is hitting the stage! 🎸 Tune in to the music channel!');
                    } else if (totalUsers === 0 && vmOnline) {
                        context.log("No users detected in voice channels, stopping VM...");
                        await manageVM('stop', computeClient, resourceGroupName, vmName);
                        await generalChannel.send('The concert’s over folks, the music bot is taking a bow! 🎤');
                    }

                    // Check if there are users in any voice channel but not for music and VM is not online
                    if (totalUsers > 0 && !vmOnline) {
                        const messages = await generalChannel.messages.fetch({ limit: 10 });
                        const commandMessage = messages.find(msg => msg.content.toLowerCase() === 'start music bot' && Date.now() - msg.createdTimestamp < 300000);

                        if (!commandMessage) {
                            context.log("No 'start music bot' command detected and users present in voice channel but not for music, taking no action...");
                            // await generalChannel.send("No 'start command' detected and no users in the music bot channel, no actions taken.");
                        }
                    }

                    // Responding to the "start music bot" command in the general channel
                    if (!vmOnline) {
                        const messages = await generalChannel.messages.fetch({ limit: 10 });
                        const commandMessage = messages.find(msg => msg.content.toLowerCase() === 'start music bot' && Date.now() - msg.createdTimestamp < 300000);

                        if (commandMessage) {
                            context.log("Start music bot command detected, starting VM...");
                            await manageVM('start', computeClient, resourceGroupName, vmName);
                            await generalChannel.send("Summoned through the mystical arts of chat, I awaken! 🧙‍♂️🎵");
                        }
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
    return vm.instanceView.statuses.find(status => status.code.startsWith('PowerState/')).code.endsWith('running');
}

// Function to start or stop the Azure VM based on the action parameter
async function manageVM(action, computeClient, resourceGroupName, vmName) {
    if (action === 'start') {
        await computeClient.virtualMachines.beginStart(resourceGroupName, vmName);
    } else if (action === 'stop') {
        await computeClient.virtualMachines.beginDeallocate(resourceGroupName, vmName);
    }
}
