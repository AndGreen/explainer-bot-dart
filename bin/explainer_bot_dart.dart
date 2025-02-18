import 'dart:io';

import 'package:televerse/televerse.dart';

void main(List<String> arguments) async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);

  final domain = Platform.environment['PUBLIC_DOMAIN'] ?? '';
  final token = Platform.environment['BOT_TOKEN'] ?? '';

  final webhook = Webhook(server, url: domain, shouldSetWebhook: true);
  final bot = Bot(token, fetcher: webhook);

  bot.command('start', (ctx) async {
    await ctx.reply("Введите слово или фразу, которую вы хотите понять");
  });

  bot.onMessage((ctx) async {
    await ctx.reply("Hello, I am ${ctx.me.firstName}. Let's start.");
  });

  print('Bot started 🚀 on $domain');

  // Start the bot :)
  await bot.start();
}
