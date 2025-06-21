@echo off
cd C:\Users\arche\StudioProjects\zishu
"C:\Users\arche\AppData\Local\Programs\Python\Python313\python.exe" scripts/preprocess_data.py --mmah "C:\Users\arche\Downloads\chinese data\makemeahanzi-master\makemeahanzi-master" --cedict "C:\Users\arche\Downloads\chinese data\cedict_1_0_ts_utf-8_mdbg\cedict_ts.u8" --unihan "C:\Users\arche\Downloads\chinese data\Unihan" --output hanzi.db
echo Done! Now move hanzi.db to assets folder
pause