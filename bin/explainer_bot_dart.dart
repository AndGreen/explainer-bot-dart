import 'dart:io';

import 'package:openai_dart/openai_dart.dart';
import 'package:televerse/televerse.dart';

import 'constants.dart';

final domain = Platform.environment['PUBLIC_DOMAIN'] ?? '';
final token = Platform.environment['BOT_TOKEN'] ?? '';
final openaiApiKey = Platform.environment['OPENAI_API_KEY'];

void main(List<String> arguments) async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  final webhook = Webhook(server, url: domain, shouldSetWebhook: true);
  final bot = Bot(token, fetcher: webhook);
  final client = OpenAIClient(apiKey: openaiApiKey);

  bot.command('start', (ctx) async {
    await ctx.reply("Введите слово или фразу, которую вы хотите понять");
  });

  bot.onMessage((ctx) async {
    final msg = await ctx.reply('...');

    final res = await client.createChatCompletion(
      request: CreateChatCompletionRequest(
        model: ChatCompletionModel.modelId('gpt-4o-mini'),
        messages: [
          ChatCompletionMessage.system(content: systemPrompt),
          ChatCompletionMessage.user(
            content: ChatCompletionUserMessageContent.string(
              'Переведи и объясни слово ${ctx.message?.text} на русском языке',
            ),
          ),
        ],
        temperature: 0,
      ),
    );

    await bot.api.editMessageText(
      ID.create(ctx.chat?.id ?? 0),
      msg.messageId,
      res.choices.first.message.content ?? '',
    );
  });

  await bot.start();
  print('Bot started 🚀 on $domain');
}
