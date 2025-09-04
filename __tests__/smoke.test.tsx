import React from 'react';
import { render } from '@testing-library/react-native';
import Home from '../app/index';

describe('FundMind smoke', () => {
  it('renders Home & CTA', () => {
    const { getByText } = render(<Home />);
    expect(getByText(/FundMind/i)).toBeTruthy();
  });
});
