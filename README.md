*z.fish* is a clone of [z](http://github.com/rupa/z) that works with [fish](https://fishshell.com)

## Install

* clone this repo (or just download the `z.fish` file in this repo)

    ```sh
    git clone https://github.com/kols/z.fish.git
    ```

* modify your `config.fish` to add a line:

    ```fish
    source /path/to/z.fish
    ```

* `cd` around for a while to build up the db

## Usage

* goes to most frecent dir matching `foo`

    ```fish
    z foo
    ```

* goes to most frecent dir matching `foo` and `bar`

    ```fish
    z foo bar
    ```
