import { BaseService } from './_base';
export class ProductService<T> extends BaseService<T> {
	location = 'products';
}
export const productService = new ProductService<Product>();
