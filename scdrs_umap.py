import argparse
import scanpy as sc
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
import matplotlib.colors as mcolors

# Arguments
parser = argparse.ArgumentParser(description="Plot composite umap")
parser.add_argument("--tissue", required=True, help="Tissue name for the title (e.g., blood, spleen)")
parser.add_argument("--atlas", required=True, help="Path to .h5ad atlas")
parser.add_argument("--score_ibd", required=True, help="Path to Acne-IBD .score.gz")
parser.add_argument("--score_cd", required=True, help="Path to Acne-CD .score.gz")
parser.add_argument("--score_uc", required=True, help="Path to Acne-UC .score.gz")
parser.add_argument("--out", required=True, help="Path to figure output")
args = parser.parse_args()

# Functions
def load_and_rename_score(file_path, trait_code, adata_obj):
    df = pd.read_csv(file_path, sep='\t', index_col=0)
    new_col_name = f'norm_score_{trait_code}'
    df = df.rename(columns={'norm_score': new_col_name})
    adata_obj.obs = adata_obj.obs.join(df[new_col_name])
    return new_col_name

def plot_result_panel(ax, score_col, trait_name, letter_label):
    sort_idx = adata.obs[score_col].abs().sort_values().index
    adata_plot = adata[sort_idx]
    
    sc.pl.umap(adata_plot, color=score_col, title=trait_name,
               cmap='coolwarm', vmin=vmin_val, vmax=vmax_val,
               colorbar_loc=None, ax=ax, show=False)
    ax.set_aspect('equal', adjustable='datalim')
    ax.text(-0.1, 1.05, letter_label, transform=ax.transAxes, size=18, weight='bold')
    return ax

# Config
sc.set_figure_params(dpi=300, facecolor='white', frameon=False, fontsize=10)
trait_names = {
    'acne_ibd': 'Acne-IBD',
    'acne_cd': 'Acne-CD',
    'acne_uc': 'Acne-UC'
}

# Load data
adata = sc.read_h5ad(args.atlas)
col_ibd = load_and_rename_score(args.score_ibd, 'acne_ibd', adata)
col_cd = load_and_rename_score(args.score_cd, 'acne_cd', adata)
col_uc = load_and_rename_score(args.score_uc, 'acne_uc', adata)

# Calculate symmetric color scale
all_scores = adata.obs[[col_ibd, col_cd, col_uc]].values
max_val = np.nanpercentile(np.abs(all_scores), 99.5)
vmin_val = -max_val
vmax_val = max_val

# Plot
fig = plt.figure(figsize=(12, 8))
gs = gridspec.GridSpec(2, 4, height_ratios=[1.1, 1], width_ratios=[1, 1, 1, 0.05], wspace=0.1, hspace=0.15)

ax_a = fig.add_subplot(gs[0, 1])
dynamic_title = f"Tabula Sapiens: {args.tissue.capitalize()}"

sc.pl.umap(adata, color='cell_type', title=dynamic_title,
           legend_loc='right margin', legend_fontsize='x-small',
           ax=ax_a, show=False)
ax_a.set_aspect('equal', adjustable='datalim')
ax_a.text(-0.1, 1.05, 'A', transform=ax_a.transAxes, size=18, weight='bold')

ax_b = fig.add_subplot(gs[1, 0])
plot_result_panel(ax_b, col_ibd, trait_names['acne_ibd'], 'B')

ax_c = fig.add_subplot(gs[1, 1])
plot_result_panel(ax_c, col_cd, trait_names['acne_cd'], 'C')

ax_d = fig.add_subplot(gs[1, 2])
plot_result_panel(ax_d, col_uc, trait_names['acne_uc'], 'D')

ax_cbar = fig.add_subplot(gs[1, 3])
norm = mcolors.Normalize(vmin=vmin_val, vmax=vmax_val)
cb = plt.colorbar(plt.cm.ScalarMappable(norm=norm, cmap='coolwarm'), cax=ax_cbar)
cb.set_label('Normalized scDRS Score', size=12, labelpad=10)

# Save
plt.savefig(args.out, bbox_inches='tight', dpi=300)