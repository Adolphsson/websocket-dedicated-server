//This script is for authentication, before logging in the game, the player will need to authenticate itself by either logging or registering a new account.
//I am using MongoDB, but you can change to whatever DB you prefer.
const express = require('express');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const bcrypt = require('bcrypt');
const nodemailer = require('nodemailer');
const cors = require('cors');
require('dotenv').config();

const app = express();

const corsOptions={
    origin:'*',
    methods:'POST,GET',
    allowHeaders:['Content-Type',"Authorization"]
}
app.use(cors(corsOptions));
app.use(bodyParser.json({ limit: '50mb' }));

//Connect to MongoDB.
const DB_URI = process.env.DATABASE_URL;
mongoose.connect(DB_URI, { useNewUrlParser: true, useUnifiedTopology: true });

mongoose.connection.on('connected', () => {
    console.log('Connected to MongoDB!');
});

mongoose.connection.on('error', (err) => {
    console.log(`Failed to connect to MongoDB: ${err.message}`);
});

//Define the map schema and model for MongoDB.
const MapSchema = new mongoose.Schema({
    data: [[String]]
});


//Define user schema and model.
//In order to play, the user needs to register a new account and verify by inputing a code received via email on my website.
const UserSchema = new mongoose.Schema({
    username: { type: String, unique: true, required: true },
    status:{ type: String, default: 'pending' },
    password: { type: String, required: false },
    email: { type: String, required: false },
    guestID: { type: String, required: false },
    confirmationToken: { type: String, required: false },
    confirmationCreated: { type: Date, required: false, expires: 60*60 }, // Verification token times out after an hour
    guestActive: { type: Date, required: false, expires: 60*60*24/**30*/ } // Guest users are deleted after a month of inactivity
});

const CharacterSchema = new mongoose.Schema({
    name: { type: String, unique: true, required: true },
    guestActive: { type: Date, required: false, expires: 60*60*24/**30*/ } // Guest user characters are deleted after a month of inactivity
});

const UserDataSchema = new mongoose.Schema({
    username: { type: String, unique: true, required: true },
    description: {type: String, unique: false, required:true},
    arrestInfo:{type: String, unique: false,required:true}
})

const UserModel = mongoose.model('userdb', UserSchema, process.env.DATABASE_COLLECTION);

const transporter = nodemailer.createTransport({
    service: process.env.SMTP_SERVICE,
    host:process.env.SMTP_HOST,
    port:process.env.SMTP_PORT,
    secure:process.env.SMTP_SECURE,
    auth:{
        user:process.env.SMTP_USER,
        pass:process.env.SMTP_PASS,
    }
});

app.use(bodyParser.json());
app.use('/healthcheck', require('express-healthcheck')());


function generateConfirmationCode() {
    return Math.floor(100000 + Math.random() * 900000).toString();
}

//Route to register new users.
//Send a http request to this route to register.
app.post('/register', async (req, res) => {
    const { username, password, email } = req.body;

    const existingUser = await UserModel.findOne({ email: email });
    if (existingUser) {
        if (existingUser.status !== 'active') {
            // The user is not active and can be removed
            // This will avoid the risk of being locked out if he/she is not verified before code expires
            await UserModel.deleteOne({ email: email });
        }
        else {
            return res.status(400).send({ action: 'register_failed', message: 'Email already exists.' });
        }
    }

    if (!username || !password || !email) {
        return res.status(400).send({ action: 'register_failed', message: 'Username, password, and email are required.' });
    }

    try {
        const confirmationCode = generateConfirmationCode();
        const hashedPassword = await bcrypt.hash(password, 10);

        const newUser = new UserModel({
            username: username,
            password: hashedPassword,
            email: email,
            confirmationToken: confirmationCode,
            confirmationCreated: Date.now() // Will expire in about 1 hour from now.
        });

        //Change the example email to the one registered in the smtp you're using.
        const mailOptions = {
            from: process.env.SMTP_USER,
            to: email,
            subject: 'Confirm Your Email',
            text: `Please confirm your email by entering this code ${confirmationCode}` // in here ${process.env.FRONTEND_URL}/confirm`
        };

        await transporter.sendMail(mailOptions);
        await newUser.save();

        return res.status(200).send({ action: 'register_successful', message: 'User registered. Please check your email for the confirmation code.', email: email });

    } catch (err) {
        console.error(err);
        res.status(500).send({ action: 'register_failed', message: err.message || 'An error occurred during registration.' });
    }
});

//Route for guest login.
//Send http request to this route to login as guest.
app.post('/guest', async (req, res) => {
    const { guest_id } = req.body;

    if (!guest_id || guest_id === '') {
        res.status(500).send({ action: 'guest_failed', message: 'Login failed.', error: 'No guest_id' });
    }

    try {
        const user = await UserModel.findOne({ guest_id });

        if (!user) {
            const newUser = new UserModel({
                username: guest_id,
                status: 'guest',
                guestID: guest_id,
                guestActive: Date.now()
            });
            newUser.save();
            res.status(200).send({ action: 'guest_successful', message: 'Logged in successfully!', username: newUser.username, guest_id: newUser.guestID });
        }
        else {
            user.guestActive = Date.now();
            user.save();
            res.status(200).send({ action: 'guest_successful', message: 'Logged in successfully!', username: user.username, guest_id: user.guestID });
        }
    } catch (err) {
        res.status(500).send({ action: 'guest_failed', message: 'Login failed.', error: err });
    }
});

//Route for user login.
//Send http request to this route to login.
app.post('/login', async (req, res) => {
    const { email, password, guest_id } = req.body;

    try {
        var user = await UserModel.findOne({ email });

        if (!user) {
            user = await UserModel.findOne({ username: email });
            if (!user) {
                return res.status(400).send({ action: 'login_failed', message: 'Invalid username or password.' });
            }
        }

        if (user.status !== 'active') {
            return res.status(400).send({ action: 'login_failed', message: 'Account not confirmed. Please check your email for confirmation.' });
        }

        if (await bcrypt.compare(password, user.password)) {
            if(user.guestActive) {
                // Guest has created account, remove guest info
                user.guestID = null;
                user.guestActive = null;
                user.save();
            }
            if (guest_id) {
                // Add guest character to user
            }
            res.status(200).send({ action: 'login_successful', message: 'Logged in successfully!', username: user.username });
        } else {
            res.status(400).send({ action: 'login_failed', message: 'Invalid username or password.' });
        }
    } catch (err) {
        res.status(500).send({ action: 'login_failed', message: 'Login failed.', error: err });
    }
});

//Route for code confirmation.
app.post('/confirm_code', async (req, res) => {
    const { email, code } = req.body;

    try {
        const user = await UserModel.findOne({ email: email });

        if (!user) {
            return res.status(400).send({ action: 'verify_failed', message: 'User not found.' });
        }

        if (user.confirmationToken === code) {
            user.status = 'active';
            user.confirmationToken = undefined;
            user.confirmationCreated = undefined;
            await user.save();
            return res.status(200).send({ action: 'verify_successful', message: 'Email confirmed successfully.' });
        } else {
            return res.status(400).send({ action: 'verify_failed', message: 'Invalid confirmation code.' });
        }
    } catch (error) {
        console.error(error);
        return res.status(500).send({ action: 'verify_failed', message: 'Error confirming email.' });
    }
});


app.listen(process.env.DATABASE_PORT,'0.0.0.0', () => {
    console.log(`Database is running on http://localhost:${process.env.DATABASE_PORT}`);
});
