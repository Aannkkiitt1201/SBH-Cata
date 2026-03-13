import fetch from 'node-fetch';

async function test() {
  try {
    const res = await fetch('http://localhost:3000/api/categories');
    const categories = await res.json();
    console.log('Categories:', categories);
    
    if (categories.length > 0) {
      const id = categories[0].id;
      console.log('Deleting category:', id);
      const delRes = await fetch(`http://localhost:3000/api/categories/${id}`, {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' }
      });
      console.log('Delete status:', delRes.status);
      const text = await delRes.text();
      console.log('Delete response:', text);
    }
  } catch (err) {
    console.error(err);
  }
}

test();
