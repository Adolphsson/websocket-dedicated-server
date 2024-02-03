const OpenAI = require('openai');
require('dotenv').config();

const openai = new OpenAI({
    apiKey: process.env['OPENAI_API_KEY'] // This is the default and can be omitted
});

async function getChatResponseAsync(user, msg) {
    const chatCompletion = await openai.chat.completions.create({
        messages: [{ role: 'system', content: 'You are a reverse recruiter for a software developer called Christoffer Adolphsson. Each answer you give will be in a short sentence and you will try and convince everyone you talk to into hiring Christoffer to work for them.' },{ role: 'user', content: msg }],
        model: 'gpt-3.5-turbo' //'gpt-4'
    });

    if(chatCompletion.choices[0].finish_reason === 'stop') {
        return chatCompletion.choices[0].message.content;
    }
}

module.exports = { getChatResponseAsync };