#include "text.h"

void construct_text (text_t *text)
{
    assert (text);
    *text = text_t {};
}

void destruct_text (text_t *text)
{
    if (!text)
        return;

    free (text->buffer);
    free (text->lines);
    *text = text_t {};
}

void find_length_of_file (FILE *source, text_t *text)
{
    assert (source && text);

    if (fseek (source, 0, SEEK_END) != 0)
    {
        text->n_symbols = 0;
        rewind (source);
        return;
    }

    long sz = ftell (source);
    if (sz < 0)
        sz = 0;
    text->n_symbols = (size_t) sz;
    rewind (source);
}

static void strip_line_comments (text_t *text)
{
    if (!text->buffer)
        return;

    for (char *p = text->buffer; *p;)
    {
        char *nl = strchr (p, '\n');
        char *line_end = nl ? nl : p + strlen (p);

        for (char *q = p; q < line_end - 1; q++)
        {
            if (q[0] == '/' && q[1] == '/')
            {
                for (char *r = q; r < line_end; r++)
                    *r = ' ';
                break;
            }
        }

        p = nl ? nl + 1 : line_end;
        if (!nl)
            break;
    }
}

void read_file (FILE *source, text_t *text, char read_regime)
{
    assert (source && text);

    free (text->buffer);
    text->buffer = nullptr;

    if (text->n_symbols == 0)
    {
        text->buffer = (char *) calloc (1, 1);
        text->buffer[0] = '\0';
        return;
    }

    text->buffer = (char *) malloc (text->n_symbols + 1);
    assert (text->buffer);

    size_t rd = fread (text->buffer, 1, text->n_symbols, source);
    text->buffer[rd] = '\0';
    text->n_symbols = rd;

    if (read_regime == NO_COMMENTS)
        strip_line_comments (text);
}

void find_lines_of_file (text_t *text, char read_regime)
{
    (void) read_regime;

    assert (text);

    text->n_lines      = 0;
    text->n_real_lines = 0;

    if (!text->buffer || text->buffer[0] == '\0')
    {
        text->n_lines      = 1;
        text->n_real_lines = 1;
        return;
    }

    for (const char *p = text->buffer; *p; p++)
    {
        if (*p == '\n')
            text->n_lines++;
    }

    text->n_lines++;
    text->n_real_lines = text->n_lines;
}

void fill_text_lines (text_t *text, char read_regime)
{
    (void) read_regime;

    assert (text);

    free (text->lines);
    text->lines = (line_t *) calloc (text->n_lines, sizeof (line_t));
    assert (text->lines);

    size_t idx       = 0;
    char * line_start = text->buffer;

    for (char *p = text->buffer; *p; p++)
    {
        if (*p == '\n')
        {
            text->lines[idx].line         = line_start;
            text->lines[idx].length       = (size_t) (p - line_start);
            text->lines[idx].real_num_line = idx;
            idx++;
            line_start = p + 1;
        }
    }

    text->lines[idx].line         = line_start;
    text->lines[idx].length       = strlen (line_start);
    text->lines[idx].real_num_line = idx;
}

void fill_text (FILE *source, text_t *text, char read_regime)
{
    assert (source && text);

    find_length_of_file (source, text);
    read_file (source, text, read_regime);
    find_lines_of_file (text, read_regime);
    fill_text_lines (text, read_regime);

    text->line_counter = 0;
    if (text->n_lines > 0 && text->lines)
        text->counter = text->lines[0].line;
    else
        text->counter = text->buffer ? text->buffer : (char *) "";
}

void print_text_lines (FILE *res, text_t *text)
{
    assert (res && text);

    for (size_t i = 0; i < text->n_lines; i++)
    {
        fprintf (res, "[%zu] len=%zu real=%zu: %.*s\n", i, text->lines[i].length,
                 text->lines[i].real_num_line, (int) text->lines[i].length, text->lines[i].line);
    }
}

void current_time (char *time_line)
{
    assert (time_line);

    time_t t  = time (nullptr);
    struct tm tm_buf;
    struct tm *lt = localtime_r (&t, &tm_buf);

    if (lt)
        strftime (time_line, CURRENT_TIME_LENGTH, "%Y-%m-%d %H:%M:%S", lt);
    else
        time_line[0] = '\0';
}
