import OpenAI from 'openai';
require('dotenv').config();

const openai = new OpenAI({
    apiKey: process.env['OPENAI_API_KEY'], // This is the default and can be omitted
});

async function getChatResponseAsync(user, msg) {
    const chatCompletion = await openai.chat.completions.create({
        messages: [{ role: 'user', content: msg }],
        model: 'gpt-3.5-turbo',
      });
    
    return chatCompletion.choices[0];
}

module.exports = { getChatResponseAsync };