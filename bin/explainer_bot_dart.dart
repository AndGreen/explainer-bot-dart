import 'dart:io';

import 'package:airtable_crud/airtable_plugin.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:televerse/televerse.dart';

import 'constants.dart';

final domain = Platform.environment['PUBLIC_DOMAIN'] ?? '';
final token = Platform.environment['BOT_TOKEN'] ?? '';
final openaiApiKey = Platform.environment['OPENAI_API_KEY'] ?? '';
final airtableApiKey = Platform.environment['AIRTABLE_TOKEN'] ?? '';
final airtableBaseId = Platform.environment['AIRTABLE_BASE_ID'] ?? '';

void main(List<String> arguments) async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  final webhook = Webhook(server, url: domain, shouldSetWebhook: true);
  final bot = Bot(token, fetcher: webhook);
  final openaiClient = OpenAIClient(apiKey: openaiApiKey);
  final airtableClient = AirtableCrud(airtableApiKey, airtableBaseId);

  bot.command('start', (ctx) async {
    await ctx.reply("Введите слово или фразу, которую вы хотите понять");
  });

  bot.onMessage((ctx) async {
    await airtableClient.createRecord('users', {
      'Request Date': DateTime.now().toIso8601String(),
      'Full Name':
          '${ctx.message?.from?.firstName} ${ctx.message?.from?.lastName}',
      'Username': ctx.message?.from?.username.toString() ?? '',
    });

    final msg = await ctx.reply('...');

    final res = await openaiClient.createChatCompletion(
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
