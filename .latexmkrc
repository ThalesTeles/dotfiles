$xelatex  = 'xelatex -shell-escape %O %S';
$pdflatex = 'pdflatex -shell-escape %O %S';
push @generated_exts, 'listing', 'cod';

# Oculta no Dolphin (.hidden) os auxiliares das pastas compiladas; Ctrl+H mostra.
# Roda no início (nomes previstos já entram antes dos arquivos nascerem) e no fim (o que de fato surgiu).
# "local $?" no END preserva o código de saída do latexmk (o VS Code depende dele).
use Cwd ();
my $ocultar_cwd = Cwd::getcwd();
sub ocultar_aux {
    my $script = "$ENV{HOME}/documents/sistema/plano-organizacao/scripts/ocultar_aux_latex.py";
    return unless -f $script;
    my @pastas;
    for my $f (@_) {
        my $p = $f =~ m{^/} ? $f : "$ocultar_cwd/$f";
        push @pastas, ($p =~ m{^(.*)/[^/]*$} ? $1 : $ocultar_cwd);
    }
    # sem -cd a saída vai para o cwd (ou para -outdir/-auxdir)
    for my $d ('.', $main::out_dir, $main::aux_dir) {
        next unless defined $d && $d ne '';
        push @pastas, ($d =~ m{^/} ? $d : "$ocultar_cwd/$d");
    }
    system('python3', '-I', $script, 'atualizar', @pastas);
}
# o VS Code passa o arquivo sem extensão ("%DOC%")
ocultar_aux(grep { !/^-/ && (-f $_ || -f "$_.tex") } @ARGV);
END { local $?; ocultar_aux(@main::file_list); }
