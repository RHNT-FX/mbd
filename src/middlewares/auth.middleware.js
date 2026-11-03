const jwt = require('jsonwebtoken');

const verifyToken = (req, res, next) => {
  const token = req.headers['authorization'];
  if (!token) return res.status(403).json({ message: 'No token provided.' });

  const tokenStr = token.split(' ')[1] || token;
  jwt.verify(tokenStr, process.env.JWT_SECRET, (err, decoded) => {
    if (err) return res.status(401).json({ message: 'Unauthorized!' });
    req.userId = decoded.id;
    req.userRole = decoded.peran;
    next();
  });
};

const requireRole = (role) => {
  return (req, res, next) => {
    if (req.userRole !== role) {
      return res.status(403).json({ message: `Require ${role} Role!` });
    }
    next();
  };
};

module.exports = { verifyToken, requireRole };
