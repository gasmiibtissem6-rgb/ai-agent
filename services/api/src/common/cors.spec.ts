import {
  isExplicitDevelopment,
  isLoopbackOrigin,
  isOriginAllowed,
} from './cors';

describe('isLoopbackOrigin', () => {
  it('accepts http loopback origins on any port', () => {
    expect(isLoopbackOrigin('http://localhost:5000')).toBe(true);
    expect(isLoopbackOrigin('http://localhost:52341')).toBe(true);
    expect(isLoopbackOrigin('http://127.0.0.1:8080')).toBe(true);
    expect(isLoopbackOrigin('http://[::1]:3000')).toBe(true);
  });

  it('accepts loopback without an explicit port', () => {
    expect(isLoopbackOrigin('http://localhost')).toBe(true);
  });

  it('rejects hostnames that merely start with a loopback name', () => {
    expect(isLoopbackOrigin('http://localhost.attacker.com')).toBe(false);
    expect(isLoopbackOrigin('http://127.0.0.1.attacker.com')).toBe(false);
    expect(isLoopbackOrigin('http://notlocalhost')).toBe(false);
  });

  it('rejects a loopback name used as userinfo or path', () => {
    expect(isLoopbackOrigin('http://attacker.com#@localhost')).toBe(false);
    expect(isLoopbackOrigin('http://attacker.com/localhost')).toBe(false);
  });

  it('rejects non-http schemes', () => {
    expect(isLoopbackOrigin('https://localhost:5000')).toBe(false);
    expect(isLoopbackOrigin('file://localhost')).toBe(false);
    expect(isLoopbackOrigin('javascript:alert(1)')).toBe(false);
  });

  it('rejects garbage instead of throwing', () => {
    expect(isLoopbackOrigin('')).toBe(false);
    expect(isLoopbackOrigin('null')).toBe(false);
    expect(isLoopbackOrigin('not a url')).toBe(false);
  });
});

describe('isOriginAllowed', () => {
  const allowlist = ['http://localhost:3000', 'https://app.ideal.example'];

  it('always accepts an allowlisted origin, in any mode', () => {
    for (const allowAnyLoopback of [true, false]) {
      expect(
        isOriginAllowed(
          'https://app.ideal.example',
          allowlist,
          allowAnyLoopback,
        ),
      ).toBe(true);
    }
  });

  it('accepts an arbitrary loopback port only when loopback is allowed', () => {
    expect(isOriginAllowed('http://localhost:52341', allowlist, true)).toBe(
      true,
    );
    expect(isOriginAllowed('http://localhost:52341', allowlist, false)).toBe(
      false,
    );
  });

  it('never accepts a non-loopback origin outside the allowlist', () => {
    expect(isOriginAllowed('https://attacker.com', allowlist, true)).toBe(
      false,
    );
    expect(
      isOriginAllowed('http://localhost.attacker.com', allowlist, true),
    ).toBe(false);
  });
});

describe('isExplicitDevelopment', () => {
  const original = process.env.NODE_ENV;
  afterEach(() => {
    process.env.NODE_ENV = original;
  });

  it('is true only when NODE_ENV is exactly "development"', () => {
    process.env.NODE_ENV = 'development';
    expect(isExplicitDevelopment()).toBe(true);
  });

  it('is false in production', () => {
    process.env.NODE_ENV = 'production';
    expect(isExplicitDevelopment()).toBe(false);
  });

  it('is false when NODE_ENV is unset, so a forgotten variable stays strict', () => {
    delete process.env.NODE_ENV;
    expect(isExplicitDevelopment()).toBe(false);
  });
});
