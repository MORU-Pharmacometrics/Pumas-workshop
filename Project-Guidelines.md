# Project Guidelines

1. Always change to project folder, you can do it by either:
   1. **Preferred method**:
      open the command pallete (`Ctrl` + `Shift` + `P` or click in the bottom-left "gear" icon) and choose `File: Open folder`.
      Then navigate to your folder and hit `Enter` or `Ok`.
   2. With a Julia REPL opened, right-click on the folder and choose `Julia: Change to This Directory`.
2. Folder structure:
   - `data/`: this is where you put all of your data.
         We subdivide this into:
         
        - `data/original/`: original "untouched" data.
        - `data/derived/`: data that was derived from the original data.
   - `src/`: Julia scripts.
   - `results/`: all of your results, i.e. analyses, tables, listings and figures.
3.  Always set your relative `data/` and `results/` paths relative to the root project folder
   (pretty much in sync with the first guideline).
   For example, your `src/data-wrangling.jl` script would have a `CSV.read` call to read the `data/original/pkdata.csv`:
   ```julia
   CSV.read("data/original/pkdata.csv", DataFrame)
   ```