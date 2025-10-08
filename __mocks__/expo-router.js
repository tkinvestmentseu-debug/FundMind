module.exports = {
  useRouter: () => ({ push: jest.fn(), back: jest.fn(), replace: jest.fn() }),
  useLocalSearchParams: () => ({}),
  Stack: ({ children }) => children || null,
  Link: ({ children }) => children || null,
};