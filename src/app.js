import express from 'express';

const app = express();

const Port = process.env.PORT || 3000;


app.get('/', (req, res) => {
    res.status(200).send('Hello from acquasitions');
})

export default app;