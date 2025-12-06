import app from './app.js';


const Port = process.env.PORT || 3000;


app.listen(Port, () => {
    console.log(`listening on http://localhost:${Port} ..`);
})