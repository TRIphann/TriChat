import { http } from '../lib/httpClient';

// Backend dùng SnakeCaseLower JSON — feedback DTO: Rating, Title, Description.
export const feedbackService = {
  async submit({ rating, title, description }) {
    return http.post('/api/feedback', {
      rating,
      title,
      description,
    });
  },
  async getMine() {
    return http.get('/api/feedback/mine');
  },
};
