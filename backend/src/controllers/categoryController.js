const prisma = require('../lib/prisma');
const { fmtCategory } = require('../lib/format');

exports.getCategories = async (req, res) => {
  try {
    const where = { userId: req.user._id };
    if (req.query.type) where.type = req.query.type;
    const categories = await prisma.category.findMany({ where, orderBy: { name: 'asc' } });
    res.json(categories.map(fmtCategory));
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.createCategory = async (req, res) => {
  try {
    const { name, type, color, icon } = req.body;
    const category = await prisma.category.create({
      data: { userId: req.user._id, name, type, color: color || '#1890ff', icon: icon || 'tag' },
    });
    res.status(201).json(fmtCategory(category));
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.updateCategory = async (req, res) => {
  try {
    const existing = await prisma.category.findFirst({
      where: { id: req.params.id, userId: req.user._id },
    });
    if (!existing) return res.status(404).json({ message: 'Category not found' });

    const { userId, ...data } = req.body;
    const category = await prisma.category.update({ where: { id: req.params.id }, data });
    res.json(fmtCategory(category));
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.deleteCategory = async (req, res) => {
  try {
    const existing = await prisma.category.findFirst({
      where: { id: req.params.id, userId: req.user._id },
    });
    if (!existing) return res.status(404).json({ message: 'Category not found' });

    await prisma.category.delete({ where: { id: req.params.id } });
    res.json({ message: 'Category deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
