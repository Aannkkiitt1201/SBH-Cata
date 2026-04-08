# SmartStock Manager (Flutter)

Production-ready stock management app for Android and iOS.

## Features
- Add/Edit/Delete stock items with camera/gallery image.
- SQLite local database using `sqflite`.
- Dashboard analytics (total units, value, low stock alert).
- Search and filter by category.
- Export PDF with image + table.
- Bonus: CSV export, JSON backup, dark/light mode.

## Preview
> These preview files are visual mockups of implemented screens.

- Home: `docs/preview/home_preview.svg`
- Add Stock: `docs/preview/add_item_preview.svg`
- PDF Export: `docs/preview/pdf_preview.svg`

## Run
```bash
flutter pub get
flutter run
```

## Notes
- Android camera/gallery permissions are in `android/app/src/main/AndroidManifest.xml`.
- iOS permissions are in `ios/Runner/Info.plist`.
- Images are stored in app documents directory under `stock_images/`.
