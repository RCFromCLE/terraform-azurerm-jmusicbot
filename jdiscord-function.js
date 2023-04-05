const axios = require('axios');
const Discord = require('discord.js');
const client = new Discord.Client();
const azure = require('azure-arm-resource');

module.exports = async function (context) {
  // Authenticate the Discord bot
  client.login(process.env.DISCORD_BOT_TOKEN);

  // Wait for the Discord client to be ready
  client.on('ready', () => {
    // Get the list of guilds (servers) that the bot is a member of
    const guilds = client.guilds.cache;

    // Iterate through each guild
    guilds.forEach(guild => {
      // Get the member count for the guild
      const memberCount = guild.memberCount;

      // If the member count is zero, shut down and deallocate the virtual machine
      if (memberCount === 0) {
        client.destroy();
        context.log('Shutting down Discord bot');

        // Set up the Azure Management SDK
        const clientId = process.env.CLIENT_ID;
        const secret = process.env.CLIENT_SECRET;
        const domain = process.env.DOMAIN;
        const subscriptionId = process.env.SUBSCRIPTION_ID;
        const resourceGroupName = process.env.RESOURCE_GROUP_NAME;
        const vmName = process.env.VM_NAME;

        const credentials = new azure.ApplicationTokenCredentials(clientId, domain, secret);
        const resourceManagementClient = new azure.ResourceManagementClient(credentials, subscriptionId);

        // Stop and deallocate the virtual machine
        resourceManagementClient.virtualMachines.powerOff(resourceGroupName, vmName, function (err, result) {
          if (err) {
            context.log(err);
          } else {
            context.log('Stopped and deallocated virtual machine');
          }
        });
      }
    });
  });
};
