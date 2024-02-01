const OpenAI = require('openai');
require('dotenv').config();

const openai = new OpenAI({
    apiKey: process.env['OPENAI_API_KEY'], // This is the default and can be omitted
});

async function getChatResponseAsync(user, msg) {
    const chatCompletion = await openai.chat.completions.create({
        messages: [{ role: 'user', content: msg }],
        model: 'gpt-4',
    });

    if(chatCompletion.choices[0].finish_reason === 'stop') {
        return chatCompletion.choices[0].message.content;
    }
}

module.exports = { getChatResponseAsync };