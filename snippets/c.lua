return {
    {
        prefix = 'f',
        body = "for (int $1 = $2; $1 < $3; ++$1) {\n\t$0\n}"
    },

    {
        prefix = 'fb',
        body = "for (int $1 = $2; $1 >= $3; --$1) {\n\t$0\n}"
    },

    {
        prefix = 'en',
        body = "\\n"
    },
}
