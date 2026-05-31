const express = require('express');
const Review = require('../models/Review');
const User = require("../models/User")
const {auth, isCustomer} = require('../middleware/auth');


const router = express.Router();



router.post('/review/:tradesmanId', auth, isCustomer, async (req, res) => {
    if (req.user.role !== 'customer') return res.status(403).json({ message: 'Only customers can leave reviews' });

    try {
        const tradesman = await User.findById(req.params.tradesmanId);
        if (!tradesman || tradesman.role !== 'tradesman') return res.status(400).json({ message: 'Invalid tradesman ID' });

        const existing = await Review.findOne({ tradesman: req.params.tradesmanId, customer: req.user.id });
        if (existing) return res.status(400).json({ message: 'You already reviewed this tradesman' });

        const { rating, comment } = req.body;

        const review = await Review.create({tradesman: req.params.tradesmanId, customer: req.user.id, rating, comment,});

        res.status(201).json(review);

    } catch (err) {
        if (err.code === 11000){
            return res.status(400).json({ error: 'You already reviewed this tradesman' });
        }
        
        res.status(500).json({ error: err.message });
    }
});


router.get('/review/:tradesmanId', async (req, res) => {
    try {
        const tradesman = await User.findById(req.params.tradesmanId);
        if (!tradesman || tradesman.role !== 'tradesman') return res.status(400).json({ message: 'Invalid tradesman ID' });

        const reviews = await Review.find({ tradesman: req.params.tradesmanId }).populate('customer', 'name profilePic').sort({ createdAt: -1 });

        let avg = 0;
        if(reviews.length > 0) {
            let total = 0;
            for (let r of reviews){
                total += r.rating;
            }
            avg = (total / reviews.length).toFixed(1);
        } 

        res.json({ averageRating: avg, total: reviews.length, reviews });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});


router.delete('/review/:id', auth, isCustomer, async (req, res) => {
    try {
        const review = await Review.findById(req.params.id);
        if(!review) return res.status(404).json({ message: 'Review not found' });

        if (review.customer.toString() !== req.user.id) return res.status(403).json({ message: 'Not your review' });

        await review.deleteOne();
        res.json({ message: 'Review deleted' });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

module.exports = router;