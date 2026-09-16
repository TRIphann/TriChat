import { http } from '../lib/httpClient';

export const feedbackService = {
  async submit({ rating, title, description }) {
    return http.post('/api/feedback', {
      Rating: rating,
      Title: title,
      Description: description,
    });
  },
  async getMine() {
    return http.get('/api/feedback/mine');
  },
};
