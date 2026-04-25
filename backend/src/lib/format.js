// Normalize Prisma records to the shape the frontend expects:
// - add _id alias for id
// - rename nested account/category back to accountId/categoryId (populated style)

const fmtUser = (u) => {
  if (!u) return u;
  const { password, otpCode, otpExpires, ...rest } = u;
  return { ...rest, _id: u.id, hasPassword: !!password };
};

const fmtAccount = (a) => a ? { ...a, _id: a.id } : a;
const fmtCategory = (c) => c ? { ...c, _id: c.id } : c;

const fmtTransaction = (tx) => {
  if (!tx) return tx;
  const out = { ...tx, _id: tx.id };
  if (tx.account !== undefined) {
    out.accountId = tx.account ? fmtAccount(tx.account) : tx.accountId;
    delete out.account;
  }
  if (tx.category !== undefined) {
    out.categoryId = tx.category ? fmtCategory(tx.category) : tx.categoryId;
    delete out.category;
  }
  return out;
};

module.exports = { fmtUser, fmtAccount, fmtCategory, fmtTransaction };
